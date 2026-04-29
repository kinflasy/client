import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/repositories/church_repository.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/repositories/member_profile_repository.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _MockChurchRepository extends Mock implements ChurchRepository {}

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

class _MockMemberProfileRepository extends Mock
    implements MemberProfileRepository {}

class _TestMembershipNotifier extends MembershipNotifier {
  _TestMembershipNotifier(this.memberships);

  final List<MembershipEntity> memberships;

  @override
  Future<List<MembershipEntity>> build() async => memberships;
}

Future<T> _readFutureProvider<T>(
  ProviderContainer container,
  dynamic provider,
) async {
  final completer = Completer<T>();
  final subscription = container.listen<AsyncValue<T>>(provider, (
    previous,
    next,
  ) {
    if (next.hasValue && !completer.isCompleted) {
      completer.complete(next.requireValue);
    } else if (next.hasError && !completer.isCompleted) {
      completer.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);

  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}

void main() {
  late _MockDepartmentRepository repository;
  late _MockChurchRepository churchRepository;
  late _MockChurchUnitRepository churchUnitRepository;
  late _MockMemberProfileRepository memberProfileRepository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockDepartmentRepository();
    churchRepository = _MockChurchRepository();
    churchUnitRepository = _MockChurchUnitRepository();
    memberProfileRepository = _MockMemberProfileRepository();
    when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
      (_) async => const Right([
        DepartmentEntity(id: 'dep-3', name: 'Zeladoria', type: 'MINISTRY'),
        DepartmentEntity(
          id: 'dep-2',
          name: 'Administrativo',
          type: 'ADMINISTRATIVE',
        ),
        DepartmentEntity(id: 'dep-1', name: 'Louvor', type: 'MINISTRY'),
      ]),
    );
    when(() => churchUnitRepository.getUnitById('unit-1')).thenAnswer(
      (_) async => const Right(
        ChurchUnitEntity(id: 'unit-1', churchId: 'church-1', name: 'Sede'),
      ),
    );
    when(() => churchRepository.getChurchById('church-1')).thenAnswer(
      (_) async => const Right(
        ChurchEntity(
          id: 'church-1',
          name: 'Igreja Batista Betel',
          slug: 'igreja-batista-betel',
          email: 'contato@betel.com',
        ),
      ),
    );
    when(
      () => memberProfileRepository.getIntegrations(any()),
    ).thenAnswer((_) async => const Right([]));

    container = ProviderContainer(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
        churchRepositoryProvider.overrideWithValue(churchRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        memberProfileRepositoryProvider.overrideWithValue(
          memberProfileRepository,
        ),
        sessionPermissionsProvider.overrideWith(
          (ref) async => const SessionPermissions(
            isAuthenticated: true,
            affiliation: Affiliation.member,
            activeUnitId: 'unit-1',
            hasMembership: true,
            integrations: [
              IntegrationEntity(
                id: 'integration-2',
                membershipId: 'membership-1',
                departmentId: 'dep-2',
                departmentType: 'ADMINISTRATIVE',
                integrationType: IntegrationType.assistant,
              ),
              IntegrationEntity(
                id: 'integration-1',
                membershipId: 'membership-1',
                departmentId: 'dep-1',
                departmentType: 'MINISTRY',
                integrationType: IntegrationType.integrant,
              ),
            ],
            isUnitAdmin: false,
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('segmentedDepartmentsProvider', () {
    test(
      'classifies departments into mine, general and administrative',
      () async {
        final result = await _readFutureProvider(
          container,
          segmentedDepartmentsProvider('unit-1'),
        );

        expect(result.myDepartments, const [
          DepartmentEntity(
            id: 'dep-2',
            name: 'Administrativo',
            type: 'ADMINISTRATIVE',
          ),
          DepartmentEntity(id: 'dep-1', name: 'Louvor', type: 'MINISTRY'),
        ]);
        expect(result.generalDepartments, const [
          DepartmentEntity(id: 'dep-1', name: 'Louvor', type: 'MINISTRY'),
          DepartmentEntity(id: 'dep-3', name: 'Zeladoria', type: 'MINISTRY'),
        ]);
        expect(result.administrativeDepartments, const [
          DepartmentEntity(
            id: 'dep-2',
            name: 'Administrativo',
            type: 'ADMINISTRATIVE',
          ),
        ]);
      },
    );

    test('returns empty myDepartments when user has no integrations', () async {
      final localContainer = ProviderContainer(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          sessionPermissionsProvider.overrideWith(
            (ref) async => const SessionPermissions(
              isAuthenticated: true,
              affiliation: Affiliation.member,
              activeUnitId: 'unit-1',
              hasMembership: true,
              integrations: [],
              isUnitAdmin: false,
            ),
          ),
        ],
      );
      addTearDown(localContainer.dispose);

      final result = await _readFutureProvider(
        localContainer,
        segmentedDepartmentsProvider('unit-1'),
      );

      expect(result.myDepartments, isEmpty);
      expect(result.generalDepartments, hasLength(2));
      expect(result.administrativeDepartments, hasLength(1));
    });
  });

  group('myDepartmentsByUnitProvider', () {
    test('returns empty when the user has no memberships', () async {
      final localContainer = ProviderContainer(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          churchRepositoryProvider.overrideWithValue(churchRepository),
          churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
          memberProfileRepositoryProvider.overrideWithValue(
            memberProfileRepository,
          ),
          membershipProvider.overrideWith(
            () => _TestMembershipNotifier(const []),
          ),
        ],
      );
      addTearDown(localContainer.dispose);

      final result = await _readFutureProvider(
        localContainer,
        myDepartmentsByUnitProvider,
      );

      expect(result, isEmpty);
      verifyNever(() => memberProfileRepository.getIntegrations(any()));
    });

    test('groups only integrated departments by unitId', () async {
      when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
        (_) async => const Right([
          DepartmentEntity(id: 'dep-1', name: 'Louvor', type: 'MINISTRY'),
          DepartmentEntity(
            id: 'dep-2',
            name: 'Secretaria',
            type: 'ADMINISTRATIVE',
          ),
          DepartmentEntity(id: 'dep-3', name: 'Intercessao', type: 'MINISTRY'),
        ]),
      );
      when(() => repository.getDepartmentsByUnitId('unit-2')).thenAnswer(
        (_) async => const Right([
          DepartmentEntity(id: 'dep-4', name: 'Midia', type: 'MINISTRY'),
          DepartmentEntity(id: 'dep-5', name: 'Recepcao', type: 'MINISTRY'),
        ]),
      );
      when(() => churchUnitRepository.getUnitById('unit-2')).thenAnswer(
        (_) async => const Right(
          ChurchUnitEntity(
            id: 'unit-2',
            churchId: 'church-1',
            name: '',
          ),
        ),
      );
      when(() => memberProfileRepository.getIntegrations('membership-1'))
          .thenAnswer(
            (_) async => const Right([
              IntegrationEntity(
                id: 'integration-1',
                membershipId: 'membership-1',
                departmentId: 'dep-1',
                departmentType: 'MINISTRY',
                integrationType: IntegrationType.integrant,
              ),
              IntegrationEntity(
                id: 'integration-2',
                membershipId: 'membership-1',
                departmentId: 'dep-2',
                departmentType: 'ADMINISTRATIVE',
                integrationType: IntegrationType.assistant,
              ),
            ]),
          );
      when(() => memberProfileRepository.getIntegrations('membership-2'))
          .thenAnswer(
            (_) async => const Right([
              IntegrationEntity(
                id: 'integration-3',
                membershipId: 'membership-2',
                departmentId: 'dep-4',
                departmentType: 'MINISTRY',
                integrationType: IntegrationType.leader,
              ),
            ]),
          );

      final localContainer = ProviderContainer(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          churchRepositoryProvider.overrideWithValue(churchRepository),
          churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
          memberProfileRepositoryProvider.overrideWithValue(
            memberProfileRepository,
          ),
          membershipProvider.overrideWith(
            () => _TestMembershipNotifier(const [
              MembershipEntity(
                id: 'membership-1',
                unitId: 'unit-1',
                affiliation: 'MEMBER',
              ),
              MembershipEntity(
                id: 'membership-2',
                unitId: 'unit-2',
                affiliation: 'LEADER',
              ),
            ]),
          ),
        ],
      );
      addTearDown(localContainer.dispose);

      final result = await _readFutureProvider(
        localContainer,
        myDepartmentsByUnitProvider,
      );

      expect(result, hasLength(2));
      expect(result[0].unitId, 'unit-2');
      expect(result[0].unitName, 'Igreja Batista Betel');
      expect(result[0].departments, const [
        DepartmentEntity(id: 'dep-4', name: 'Midia', type: 'MINISTRY'),
      ]);

      expect(result[1].unitId, 'unit-1');
      expect(result[1].unitName, 'Sede');
      expect(result[1].departments, const [
        DepartmentEntity(
          id: 'dep-1',
          name: 'Louvor',
          type: 'MINISTRY',
        ),
        DepartmentEntity(
          id: 'dep-2',
          name: 'Secretaria',
          type: 'ADMINISTRATIVE',
        ),
      ]);
    });

    test('falls back to church name when unit name is unavailable', () async {
      when(() => churchUnitRepository.getUnitById('unit-1')).thenAnswer(
        (_) async => const Right(
          ChurchUnitEntity(id: 'unit-1', churchId: 'church-1', name: null),
        ),
      );
      when(() => memberProfileRepository.getIntegrations('membership-1'))
          .thenAnswer(
            (_) async => const Right([
              IntegrationEntity(
                id: 'integration-1',
                membershipId: 'membership-1',
                departmentId: 'dep-1',
                departmentType: 'MINISTRY',
                integrationType: IntegrationType.integrant,
              ),
            ]),
          );

      final localContainer = ProviderContainer(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          churchRepositoryProvider.overrideWithValue(churchRepository),
          churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
          memberProfileRepositoryProvider.overrideWithValue(
            memberProfileRepository,
          ),
          membershipProvider.overrideWith(
            () => _TestMembershipNotifier(const [
              MembershipEntity(
                id: 'membership-1',
                unitId: 'unit-1',
                affiliation: 'MEMBER',
              ),
            ]),
          ),
        ],
      );
      addTearDown(localContainer.dispose);

      final result = await _readFutureProvider(
        localContainer,
        myDepartmentsByUnitProvider,
      );

      expect(result, hasLength(1));
      expect(result.first.unitName, 'Igreja Batista Betel');
    });
  });
}
