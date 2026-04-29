import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/presentation/widgets/church_profile_tabs.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Widget buildSubject({
    required SegmentedDepartments segmentedDepartments,
    SessionPermissions permissions = const SessionPermissions(
      isAuthenticated: true,
      affiliation: Affiliation.member,
      activeUnitId: 'unit-1',
      hasMembership: true,
      integrations: [
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
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.homeChurch,
      routes: [
        GoRoute(
          path: AppRoutes.homeChurch,
          builder: (context, state) =>
              const Scaffold(body: DepartmentsTab(unitId: 'unit-1')),
          routes: [
            GoRoute(
              path: 'departamentos/categoria/:category',
              name: AppRoutes.homeChurchDepartmentsCategoryName,
              builder: (context, state) => Scaffold(
                body: Text('category:${state.pathParameters['category']}'),
              ),
            ),
            GoRoute(
              path: 'departamentos/:id',
              name: AppRoutes.homeChurchDepartmentDetailName,
              builder: (context, state) =>
                  const Scaffold(body: Text('detail-shell')),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        segmentedDepartmentsProvider.overrideWith(
          (ref, unitId) async => segmentedDepartments,
        ),
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('hides my departments when the list is empty', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        segmentedDepartments: const SegmentedDepartments(
          myDepartments: [],
          generalDepartments: [],
          administrativeDepartments: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meus departamentos'), findsNothing);
    expect(find.text('Nenhum departamento encontrado.'), findsOneWidget);
  });

  testWidgets('shows my departments when the list has items', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        segmentedDepartments: const SegmentedDepartments(
          myDepartments: [_louvorDepartment, _secretariaDepartment],
          generalDepartments: [_louvorDepartment],
          administrativeDepartments: [_secretariaDepartment],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meus departamentos'), findsOneWidget);
    expect(find.text('Louvor'), findsNWidgets(2));
    expect(find.text('Secretaria'), findsNWidgets(2));
  });

  testWidgets('renders general and administrative sections', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        segmentedDepartments: const SegmentedDepartments(
          myDepartments: [],
          generalDepartments: [_louvorDepartment],
          administrativeDepartments: [_secretariaDepartment],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Administrativo'), findsOneWidget);
    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Secretaria'), findsOneWidget);
  });

  testWidgets('opens category route from section header', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        segmentedDepartments: const SegmentedDepartments(
          myDepartments: [_louvorDepartment],
          generalDepartments: [_louvorDepartment],
          administrativeDepartments: [_secretariaDepartment],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geral'));
    await tester.pumpAndSettle();

    expect(find.text('category:general'), findsOneWidget);
  });

  testWidgets('navigates from church departments tab to shell detail route', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        segmentedDepartments: const SegmentedDepartments(
          myDepartments: [_louvorDepartment],
          generalDepartments: [_louvorDepartment],
          administrativeDepartments: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Louvor').first);
    await tester.pumpAndSettle();

    expect(find.text('detail-shell'), findsOneWidget);
  });

  testWidgets('keeps forbidden department card visible without navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        segmentedDepartments: const SegmentedDepartments(
          myDepartments: [_secretariaDepartment],
          generalDepartments: [],
          administrativeDepartments: [_secretariaDepartment],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Secretaria').first);
    await tester.pumpAndSettle();

    expect(find.text('detail-shell'), findsNothing);
    expect(find.text('Secretaria'), findsNWidgets(2));
  });

  testWidgets('unit admin can open any department card from the church tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        segmentedDepartments: const SegmentedDepartments(
          myDepartments: [],
          generalDepartments: [],
          administrativeDepartments: [_secretariaDepartment],
        ),
        permissions: const SessionPermissions(
          isAuthenticated: true,
          affiliation: Affiliation.unitAdmin,
          activeUnitId: 'unit-1',
          hasMembership: true,
          integrations: [],
          isUnitAdmin: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Secretaria').first);
    await tester.pumpAndSettle();

    expect(find.text('detail-shell'), findsOneWidget);
  });
}

const _louvorDepartment = DepartmentEntity(
  id: 'dep-1',
  name: 'Louvor',
  slug: 'louvor',
  type: 'MINISTRY',
);

const _secretariaDepartment = DepartmentEntity(
  id: 'dep-2',
  name: 'Secretaria',
  slug: 'secretaria',
  type: 'ADMINISTRATIVE',
);
