import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/presentation/screens/department_category_list_screen.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows loading state while active membership is loading', (
    tester,
  ) async {
    final completer = Completer<MembershipEntity?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMembershipProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(
          home: DepartmentCategoryListScreen(category: 'general'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows category title, counter and hides add button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-1',
              unitId: 'unit-1',
              affiliation: 'MEMBER',
            ),
          ),
          sessionPermissionsProvider.overrideWith(
            (ref) async => const SessionPermissions(
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
          ),
          segmentedDepartmentsProvider.overrideWith(
            (ref, unitId) async => const SegmentedDepartments(
              myDepartments: [_louvorDepartment],
              generalDepartments: [_louvorDepartment],
              administrativeDepartments: [_secretariaDepartment],
            ),
          ),
        ],
        child: const MaterialApp(
          home: DepartmentCategoryListScreen(category: 'administrative'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Administrativo'), findsOneWidget);
    expect(find.text('1 departamentos'), findsOneWidget);
    expect(find.text('Secretaria'), findsOneWidget);
    expect(find.text('Adicionar departamento'), findsNothing);
  });

  testWidgets('filters category list by typing and updates empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-1',
              unitId: 'unit-1',
              affiliation: 'MEMBER',
            ),
          ),
          sessionPermissionsProvider.overrideWith(
            (ref) async => const SessionPermissions(
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
          ),
          segmentedDepartmentsProvider.overrideWith(
            (ref, unitId) async => const SegmentedDepartments(
              myDepartments: [_louvorDepartment],
              generalDepartments: [_louvorDepartment, _midiaDepartment],
              administrativeDepartments: [],
            ),
          ),
        ],
        child: const MaterialApp(
          home: DepartmentCategoryListScreen(category: 'general'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 departamentos'), findsOneWidget);
    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Midia'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'lou');
    await tester.pumpAndSettle();

    expect(find.text('1 departamentos'), findsOneWidget);
    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Midia'), findsNothing);

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum departamento encontrado para esta busca.'),
      findsOneWidget,
    );
    expect(find.text('0 departamentos'), findsOneWidget);
  });

  testWidgets('navigates to shell department detail from category list', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.homeChurchDepartmentsCategory.replaceFirst(
        ':category',
        'general',
      ),
      routes: [
        GoRoute(
          path: AppRoutes.homeChurch,
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: 'departamentos/categoria/:category',
              builder: (context, state) => DepartmentCategoryListScreen(
                category: state.pathParameters['category']!,
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-1',
              unitId: 'unit-1',
              affiliation: 'MEMBER',
            ),
          ),
          sessionPermissionsProvider.overrideWith(
            (ref) async => const SessionPermissions(
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
          ),
          segmentedDepartmentsProvider.overrideWith(
            (ref, unitId) async => const SegmentedDepartments(
              myDepartments: [_louvorDepartment],
              generalDepartments: [_louvorDepartment],
              administrativeDepartments: [],
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Louvor'));
    await tester.pumpAndSettle();

    expect(find.text('detail-shell'), findsOneWidget);
  });

  testWidgets('keeps forbidden department card visible without navigation', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.homeChurchDepartmentsCategory.replaceFirst(
        ':category',
        'administrative',
      ),
      routes: [
        GoRoute(
          path: AppRoutes.homeChurch,
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: 'departamentos/categoria/:category',
              builder: (context, state) => DepartmentCategoryListScreen(
                category: state.pathParameters['category']!,
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-1',
              unitId: 'unit-1',
              affiliation: 'MEMBER',
            ),
          ),
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
          segmentedDepartmentsProvider.overrideWith(
            (ref, unitId) async => const SegmentedDepartments(
              myDepartments: [_secretariaDepartment],
              generalDepartments: [],
              administrativeDepartments: [_secretariaDepartment],
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Secretaria'));
    await tester.pumpAndSettle();

    expect(find.text('detail-shell'), findsNothing);
    expect(find.text('Secretaria'), findsOneWidget);
  });

  testWidgets('unit admin can open any department from category list', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.homeChurchDepartmentsCategory.replaceFirst(
        ':category',
        'administrative',
      ),
      routes: [
        GoRoute(
          path: AppRoutes.homeChurch,
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: 'departamentos/categoria/:category',
              builder: (context, state) => DepartmentCategoryListScreen(
                category: state.pathParameters['category']!,
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-1',
              unitId: 'unit-1',
              affiliation: 'UNIT_ADMIN',
            ),
          ),
          sessionPermissionsProvider.overrideWith(
            (ref) async => const SessionPermissions(
              isAuthenticated: true,
              affiliation: Affiliation.unitAdmin,
              activeUnitId: 'unit-1',
              hasMembership: true,
              integrations: [],
              isUnitAdmin: true,
            ),
          ),
          segmentedDepartmentsProvider.overrideWith(
            (ref, unitId) async => const SegmentedDepartments(
              myDepartments: [],
              generalDepartments: [],
              administrativeDepartments: [_secretariaDepartment],
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Secretaria'));
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

const _midiaDepartment = DepartmentEntity(
  id: 'dep-2',
  name: 'Midia',
  slug: 'midia',
  type: 'MINISTRY',
);

const _secretariaDepartment = DepartmentEntity(
  id: 'dep-3',
  name: 'Secretaria',
  slug: 'secretaria',
  type: 'ADMINISTRATIVE',
);
