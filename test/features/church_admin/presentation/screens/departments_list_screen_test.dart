import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/providers/church_department_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/church_admin/presentation/screens/admin_panel_screen.dart';
import 'package:client/features/church_admin/presentation/screens/departments_list_screen.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('navigates to departments screen from admin panel', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.adminPanel,
      routes: [
        GoRoute(
          path: AppRoutes.adminPanel,
          builder: (context, state) => const AdminPanelScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminDepartments,
          builder: (context, state) =>
              const Scaffold(body: Text('departments')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Departamentos'));
    await tester.pumpAndSettle();

    expect(find.text('departments'), findsOneWidget);
  });

  testWidgets('shows loading state while active membership is loading', (
    tester,
  ) async {
    final completer = Completer<MembershipEntity?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMembershipProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: DepartmentsListScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when active unit is missing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activeMembershipProvider.overrideWith((ref) async => null)],
        child: const MaterialApp(home: DepartmentsListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma unidade ativa encontrada.'), findsOneWidget);
    expect(find.text('Buscar departamento por nome'), findsNothing);
  });

  testWidgets('shows error state when departments fail to load', (
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
          churchDepartmentsProvider.overrideWith(
            (ref, unitId) => Future<List<ChurchDepartmentEntity>>.error(
              const NetworkFailure('Falha ao carregar departamentos'),
            ),
          ),
        ],
        child: const MaterialApp(home: DepartmentsListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falha ao carregar departamentos'), findsOneWidget);
    expect(find.text('0 departamentos'), findsOneWidget);
    expect(find.text('Adicionar departamento'), findsOneWidget);
  });

  testWidgets('shows registered-empty state when there are no departments', (
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
          churchDepartmentsProvider.overrideWith((ref, unitId) async => []),
        ],
        child: const MaterialApp(home: DepartmentsListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buscar departamento por nome'), findsOneWidget);
    expect(find.text('0 departamentos'), findsOneWidget);
    expect(find.text('Nenhum departamento cadastrado.'), findsOneWidget);
    expect(find.text('Adicionar departamento'), findsOneWidget);
  });

  testWidgets('filters list by typing and updates empty state for search', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.adminDepartments,
      routes: [
        GoRoute(
          path: AppRoutes.adminDepartments,
          builder: (context, state) => const DepartmentsListScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminDepartmentsRegister,
          builder: (context, state) =>
              const Scaffold(body: Text('register department')),
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
          churchDepartmentsProvider.overrideWith(
            (ref, unitId) async => const [
              ChurchDepartmentEntity(
                id: 'dept-2',
                name: 'Secretaria',
                type: 'ADMINISTRATIVE',
              ),
              ChurchDepartmentEntity(
                id: 'dept-1',
                name: 'Ministério de Louvor',
                slug: 'louvor',
                type: 'MINISTRY',
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 departamentos'), findsOneWidget);
    expect(find.text('Ministério de Louvor'), findsOneWidget);
    expect(find.text('Secretaria'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ministerio');
    await tester.pumpAndSettle();

    expect(find.text('1 departamentos'), findsOneWidget);
    expect(find.text('Ministério de Louvor'), findsOneWidget);
    expect(find.text('Secretaria'), findsNothing);

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum departamento encontrado para esta busca.'),
      findsOneWidget,
    );
    expect(find.text('0 departamentos'), findsOneWidget);

    await tester.tap(find.text('Adicionar departamento'));
    await tester.pumpAndSettle();

    expect(find.text('register department'), findsOneWidget);
  });
}
