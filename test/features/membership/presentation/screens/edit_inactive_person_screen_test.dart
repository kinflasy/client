import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/data/models/address_model.dart';
import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:client/features/membership/data/models/person_profile_model.dart';
import 'package:client/features/membership/data/models/update_inactive_person_request_model.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:client/features/membership/domain/repositories/member_profile_repository.dart';
import 'package:client/features/membership/presentation/screens/edit_inactive_person_screen.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeMemberProfileRepository implements MemberProfileRepository {
  UpdateInactivePersonRequestModel? lastRequest;
  Failure? updateFailure;

  @override
  Future<Either<Failure, void>> updateInactivePerson({
    required String personId,
    required UpdateInactivePersonRequestModel request,
  }) async {
    lastRequest = request;
    if (updateFailure != null) return Left(updateFailure!);
    return const Right(null);
  }

  @override
  Future<Either<Failure, ActiveMembershipModel>> getActiveMembership({
    required String unitId,
    required String personId,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, AddressModel>> getAddress(String addressId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<IntegrationEntity>>> getIntegrations(
    String membershipId,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, PersonProfileModel>> getPersonProfile(
    String personId,
  ) async => throw UnimplementedError();
}

void main() {
  Finder fieldAt(int index) {
    return find.byType(TextFormField).at(index);
  }

  final profile = MemberProfileEntity(
    personId: 'person-1',
    membershipId: 'membership-1',
    personType: PersonType.inactive,
    fullName: 'Maria Souza',
    nickname: 'Mari',
    gender: 'FEMALE',
    birthDate: DateTime(1995, 2, 3),
    phone: '99999-1111',
    email: 'maria@dev.com',
    address: 'Rua A, 123, Centro, Fortaleza, CE | Apto 2 - Perto da praca - 60000-000',
    addressDetails: AddressDetailsEntity(
      id: 'address-1',
      zip: '60000-000',
      country: 'Brasil',
      state: 'CE',
      city: 'Fortaleza',
      neighborhood: 'Centro',
      street: 'Rua A',
      number: '123',
      complement: 'Apto 2',
      reference: 'Perto da praca',
    ),
    affiliation: 'VISITOR',
  );

  testWidgets('shows prefilled personal and address fields', (tester) async {
    final repository = _FakeMemberProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberProfileRepositoryProvider.overrideWithValue(repository),
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-1',
              unitId: 'unit-1',
              affiliation: 'VISITOR',
            ),
          ),
        ],
        child: MaterialApp(
          home: EditInactivePersonScreen(
            personId: 'person-1',
            initialProfile: profile,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(fieldAt(0)).controller?.text,
      'Maria Souza',
    );
    expect(
      tester.widget<TextFormField>(fieldAt(4)).controller?.text,
      'maria@dev.com',
    );
    expect(find.text('Editar cadastro'), findsOneWidget);
  });

}
