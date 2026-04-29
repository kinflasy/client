import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

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

  setUp(() {
    repository = _MockDepartmentRepository();
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

    container = ProviderContainer(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
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
}
