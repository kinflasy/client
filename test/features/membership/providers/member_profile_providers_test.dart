import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/membership/data/models/address_model.dart';
import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:client/features/membership/data/models/person_profile_model.dart';
import 'package:client/features/membership/data/models/update_inactive_person_request_model.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:client/features/membership/domain/repositories/member_profile_repository.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:client/core/domain/enums/integration_type.dart';

class _FakeMemberProfileRepository implements MemberProfileRepository {
  _FakeMemberProfileRepository({
    required this.personResult,
    required this.membershipResult,
    this.addressResult,
    this.integrationsResult,
  });

  final Either<Failure, PersonProfileModel> personResult;
  final Either<Failure, ActiveMembershipModel> membershipResult;
  final Either<Failure, AddressModel>? addressResult;
  final Either<Failure, List<IntegrationEntity>>? integrationsResult;

  @override
  Future<Either<Failure, ActiveMembershipModel>> getActiveMembership({
    required String unitId,
    required String personId,
  }) async => membershipResult;

  @override
  Future<Either<Failure, AddressModel>> getAddress(String addressId) async =>
      addressResult ?? const Left(NetworkFailure('Endereco indisponivel'));

  @override
  Future<Either<Failure, List<IntegrationEntity>>> getIntegrations(
    String membershipId,
  ) async => integrationsResult ?? const Right([]);

  @override
  Future<Either<Failure, PersonProfileModel>> getPersonProfile(
    String personId,
  ) async => personResult;

  @override
  Future<Either<Failure, void>> updateInactivePerson({
    required String personId,
    required UpdateInactivePersonRequestModel request,
  }) async => const Right(null);
}

void main() {
  test('PersonProfileModel parses USER payload', () {
    final model = PersonProfileModel.fromJson({
      'type': 'USER',
      'id': 'person-1',
      'fullName': 'Ana Maria',
      'nickname': 'Aninha',
      'gender': 'FEMALE',
      'birthDate': '1990-04-10',
      'phone': '99999-0000',
      'addressId': 'address-1',
      'age': 36,
      'email': 'ana@dev.com',
    });

    expect(model.type, PersonType.user);
    expect(model.email, 'ana@dev.com');
    expect(model.age, 36);
    expect(model.addressId, 'address-1');
  });

  test('PersonProfileModel parses INACTIVE payload', () {
    final model = PersonProfileModel.fromJson({
      'type': 'INACTIVE',
      'id': 'person-2',
      'fullName': 'Carlos Lima',
      'gender': 'MALE',
      'birthDate': '1988-01-01',
      'age': '38',
      'email': 'carlos@dev.com',
    });

    expect(model.type, PersonType.inactive);
    expect(model.age, 38);
    expect(model.email, 'carlos@dev.com');
  });

  test(
    'loadMembershipIntegrations returns integrations from repository',
    () async {
      final repository = _FakeMemberProfileRepository(
        personResult: Right(
          PersonProfileModel.fromJson({
            'type': 'USER',
            'id': 'person-0',
            'fullName': 'Teste',
            'gender': 'FEMALE',
          }),
        ),
        membershipResult: Right(
          ActiveMembershipModel.fromJson({
            'id': 'membership-0',
            'unitId': 'unit-1',
            'personId': 'person-0',
            'affiliation': 'MEMBER',
          }),
        ),
        integrationsResult: Right([
          const IntegrationEntity(
            id: 'integration-1',
            membershipId: 'membership-0',
            departmentId: 'dept-1',
            departmentType: 'MINISTRY',
            integrationType: IntegrationType.integrant,
          ),
        ]),
      );

      final integrations = await loadMembershipIntegrations(
        repository: repository,
        membershipId: 'membership-0',
      );

      expect(integrations, hasLength(1));
      expect(integrations.single.departmentId, 'dept-1');
    },
  );

  test(
    'resolveMemberProfile prioritizes backend age and resolves department names',
    () async {
      final repository = _FakeMemberProfileRepository(
        personResult: Right(
          PersonProfileModel.fromJson({
            'type': 'USER',
            'id': 'person-1',
            'fullName': 'Ana Maria',
            'gender': 'FEMALE',
            'birthDate': '1990-04-10',
            'age': 40,
            'addressId': 'address-1',
            'email': 'ana@dev.com',
          }),
        ),
        membershipResult: Right(
          ActiveMembershipModel.fromJson({
            'id': 'membership-1',
            'unitId': 'unit-1',
            'personId': 'person-1',
            'affiliation': 'MEMBER',
            'entryDate': '2020-04-10',
          }),
        ),
        addressResult: Right(
          AddressModel.fromJson({
            'id': 'address-1',
            'street': 'Rua A',
            'number': '10',
            'city': 'Fortaleza',
            'state': 'CE',
          }),
        ),
        integrationsResult: Right([
          const IntegrationEntity(
            id: 'integration-1',
            membershipId: 'membership-1',
            departmentId: 'dept-1',
            departmentType: 'MINISTRY',
            integrationType: IntegrationType.leader,
          ),
        ]),
      );

      final profile = await resolveMemberProfile(
        personId: 'person-1',
        unitId: 'unit-1',
        repository: repository,
        fetchDepartments: () async => const [
          DepartmentEntity(id: 'dept-1', name: 'Louvor', type: 'MINISTRY'),
        ],
      );

      expect(profile.age, 40);
      expect(profile.address, 'Rua A, 10, Fortaleza, CE');
      expect(profile.addressDetails?.city, 'Fortaleza');
      expect(profile.integrations.single.departmentName, 'Louvor');
      expect(
        profile.integrations.single.integrationType,
        IntegrationType.leader,
      );
    },
  );

  test(
    'resolveMemberProfile falls back to birthDate when age is absent',
    () async {
      final repository = _FakeMemberProfileRepository(
        personResult: Right(
          PersonProfileModel.fromJson({
            'type': 'INACTIVE',
            'id': 'person-2',
            'fullName': 'Bruno Lima',
            'gender': 'MALE',
            'birthDate': '2000-01-01',
          }),
        ),
        membershipResult: Right(
          ActiveMembershipModel.fromJson({
            'id': 'membership-2',
            'unitId': 'unit-1',
            'personId': 'person-2',
            'affiliation': 'VISITOR',
          }),
        ),
      );

      final profile = await resolveMemberProfile(
        personId: 'person-2',
        unitId: 'unit-1',
        repository: repository,
        fetchDepartments: () async => const [],
      );

      expect(profile.age, isNotNull);
      expect(profile.personType, PersonType.inactive);
    },
  );

  test('resolveMemberProfile tolerates partial address failure', () async {
    final repository = _FakeMemberProfileRepository(
      personResult: Right(
        PersonProfileModel.fromJson({
          'type': 'USER',
          'id': 'person-3',
          'fullName': 'Carla Souza',
          'gender': 'FEMALE',
          'addressId': 'address-3',
        }),
      ),
      membershipResult: Right(
        ActiveMembershipModel.fromJson({
          'id': 'membership-3',
          'unitId': 'unit-1',
          'personId': 'person-3',
          'affiliation': 'CONGREGATED',
        }),
      ),
      addressResult: const Left(NetworkFailure('Falha no endereco')),
    );

    final profile = await resolveMemberProfile(
      personId: 'person-3',
      unitId: 'unit-1',
      repository: repository,
      fetchDepartments: () async => const [],
    );

    expect(profile.address, isNull);
  });

  test('resolveMemberProfile tolerates partial integrations failure', () async {
    final repository = _FakeMemberProfileRepository(
      personResult: Right(
        PersonProfileModel.fromJson({
          'type': 'USER',
          'id': 'person-4',
          'fullName': 'Daniel Rocha',
          'gender': 'MALE',
        }),
      ),
      membershipResult: Right(
        ActiveMembershipModel.fromJson({
          'id': 'membership-4',
          'unitId': 'unit-1',
          'personId': 'person-4',
          'affiliation': 'MEMBER',
        }),
      ),
      integrationsResult: const Left(NetworkFailure('Falha nas integracoes')),
    );

    final profile = await resolveMemberProfile(
      personId: 'person-4',
      unitId: 'unit-1',
      repository: repository,
      fetchDepartments: () async => const [
        DepartmentEntity(id: 'dept-1', name: 'Midia'),
      ],
    );

    expect(profile.integrations, isEmpty);
  });
}
