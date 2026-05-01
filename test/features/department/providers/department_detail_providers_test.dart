import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _FakeIntegrationRequestModel extends Fake
    implements IntegrationRequestModel {}

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
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(_FakeIntegrationRequestModel());
  });

  setUp(() {
    repository = _MockDepartmentRepository();
    container = ProviderContainer(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'active-membership',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('departmentDetailProvider', () {
    test('returns department detail from repository', () async {
      when(() => repository.getDepartmentById('dep-1')).thenAnswer(
        (_) async => const Right(
          DepartmentDetailEntity(
            id: 'dep-1',
            name: 'Louvor',
            slug: 'louvor',
            type: 'MINISTRY',
          ),
        ),
      );

      final result = await _readFutureProvider(
        container,
        departmentDetailProvider('dep-1'),
      );

      expect(result.name, 'Louvor');
      expect(result.slug, 'louvor');
    });

    test('surfaces repository failure', () async {
      when(() => repository.getDepartmentById('dep-1')).thenAnswer(
        (_) async =>
            const Left(NetworkFailure('Falha ao carregar departamento')),
      );

      await expectLater(
        _readFutureProvider(container, departmentDetailProvider('dep-1')),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('departmentParticipantsProvider', () {
    test('returns participants from repository', () async {
      when(() => repository.getParticipants('dep-1')).thenAnswer(
        (_) async => const Right([
          DepartmentParticipantEntity(
            personId: 'person-1',
            fullName: 'Maria Silva',
            affiliation: 'MEMBER',
            gender: 'FEMALE',
          ),
        ]),
      );

      final result = await _readFutureProvider(
        container,
        departmentParticipantsProvider('dep-1'),
      );

      expect(result, hasLength(1));
      expect(result.first.fullName, 'Maria Silva');
    });

    test('returns empty list when repository has no participants', () async {
      when(
        () => repository.getParticipants('dep-1'),
      ).thenAnswer((_) async => const Right(<DepartmentParticipantEntity>[]));

      final result = await _readFutureProvider(
        container,
        departmentParticipantsProvider('dep-1'),
      );

      expect(result, isEmpty);
    });

    test('surfaces repository failure', () async {
      when(() => repository.getParticipants('dep-1')).thenAnswer(
        (_) async =>
            const Left(NetworkFailure('Falha ao carregar participantes')),
      );

      await expectLater(
        _readFutureProvider(container, departmentParticipantsProvider('dep-1')),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('AddDepartmentParticipantsNotifier', () {
    test('returns multiple successes', () async {
      when(
        () => repository.addParticipant('dep-1', any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await container
          .read(addDepartmentParticipantsProvider.notifier)
          .addParticipants(
            departmentId: 'dep-1',
            membershipIds: ['membership-1', 'membership-2'],
          );

      expect(result.successCount, 2);
      expect(result.failureCount, 0);
      expect(result.hasSuccess, isTrue);
      expect(result.hasFailures, isFalse);
      verify(() => repository.addParticipant('dep-1', any())).called(2);
    });

    test('returns partial success and failure count', () async {
      when(
        () => repository.addParticipant(
          'dep-1',
          any(
            that: predicate<IntegrationRequestModel>(
              (request) => request.membershipId == 'membership-1',
            ),
          ),
        ),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => repository.addParticipant(
          'dep-1',
          any(
            that: predicate<IntegrationRequestModel>(
              (request) => request.membershipId == 'membership-2',
            ),
          ),
        ),
      ).thenAnswer(
        (_) async => const Left(ValidationFailure('Participante inválido.')),
      );

      final result = await container
          .read(addDepartmentParticipantsProvider.notifier)
          .addParticipants(
            departmentId: 'dep-1',
            membershipIds: ['membership-1', 'membership-2'],
          );

      expect(result.successCount, 1);
      expect(result.failureCount, 1);
      expect(result.hasSuccess, isTrue);
      expect(result.hasFailures, isTrue);
    });

    test('deduplicates membership ids before calling repository', () async {
      when(
        () => repository.addParticipant('dep-1', any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await container
          .read(addDepartmentParticipantsProvider.notifier)
          .addParticipants(
            departmentId: 'dep-1',
            membershipIds: ['membership-1', 'membership-1'],
          );

      expect(result.successCount, 1);
      expect(result.failureCount, 0);
      verify(() => repository.addParticipant('dep-1', any())).called(1);
    });

    test('invalidates department participants after success', () async {
      when(
        () => repository.getParticipants('dep-1'),
      ).thenAnswer((_) async => const Right(<DepartmentParticipantEntity>[]));
      when(
        () => repository.addParticipant('dep-1', any()),
      ).thenAnswer((_) async => const Right(unit));

      final subscription = container.listen(
        departmentParticipantsProvider('dep-1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(departmentParticipantsProvider('dep-1').future);
      await container
          .read(addDepartmentParticipantsProvider.notifier)
          .addParticipants(
            departmentId: 'dep-1',
            membershipIds: ['membership-1'],
          );
      await container.read(departmentParticipantsProvider('dep-1').future);

      verify(() => repository.getParticipants('dep-1')).called(2);
    });

    test('invalidates permissions when active membership was added', () async {
      var integrationsLoadCount = 0;
      var permissionsLoadCount = 0;
      final scopedContainer = ProviderContainer(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'active-membership',
              unitId: 'unit-1',
              affiliation: 'MEMBER',
            ),
          ),
          myDepartmentIntegrationsProvider.overrideWith((ref) async {
            integrationsLoadCount++;
            return const <IntegrationEntity>[];
          }),
          sessionPermissionsProvider.overrideWith((ref) async {
            permissionsLoadCount++;
            return const SessionPermissions(
              isAuthenticated: true,
              affiliation: Affiliation.member,
              activeUnitId: 'unit-1',
              hasMembership: true,
              integrations: [
                IntegrationEntity(
                  id: 'integration-1',
                  membershipId: 'active-membership',
                  departmentId: 'dep-1',
                  departmentType: 'MINISTRY',
                  integrationType: IntegrationType.integrant,
                ),
              ],
              isUnitAdmin: false,
            );
          }),
        ],
      );
      addTearDown(scopedContainer.dispose);

      when(
        () => repository.addParticipant('dep-1', any()),
      ).thenAnswer((_) async => const Right(unit));

      final integrationsSubscription = scopedContainer.listen(
        myDepartmentIntegrationsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final permissionsSubscription = scopedContainer.listen(
        sessionPermissionsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(integrationsSubscription.close);
      addTearDown(permissionsSubscription.close);

      await scopedContainer.read(myDepartmentIntegrationsProvider.future);
      await scopedContainer.read(sessionPermissionsProvider.future);
      await scopedContainer
          .read(addDepartmentParticipantsProvider.notifier)
          .addParticipants(
            departmentId: 'dep-1',
            membershipIds: ['active-membership'],
          );
      await scopedContainer.read(myDepartmentIntegrationsProvider.future);
      await scopedContainer.read(sessionPermissionsProvider.future);

      expect(integrationsLoadCount, 2);
      expect(permissionsLoadCount, 2);
    });
  });
}
