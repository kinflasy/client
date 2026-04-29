import 'package:client/core/router/app_routes.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/entities/my_departments_unit_group.dart';
import 'package:client/features/department/presentation/screens/my_departments_menu_screen.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders grouped departments by unit and category', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myDepartmentsByUnitProvider.overrideWith(
            (ref) async => const [
              MyDepartmentsUnitGroup(
                unitId: 'unit-1',
                unitName: 'Igreja Batista Betel',
                departments: [_louvorDepartment, _secretariaDepartment],
              ),
              MyDepartmentsUnitGroup(
                unitId: 'unit-2',
                unitName: 'Congregação Norte',
                departments: [_midiaDepartment],
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: MyDepartmentsMenuScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meus departamentos'), findsOneWidget);
    expect(find.text('Igreja Batista Betel'), findsOneWidget);
    expect(find.text('Congregação Norte'), findsOneWidget);
    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Secretaria'), findsOneWidget);
    expect(find.text('Midia'), findsOneWidget);
  });

  testWidgets('shows coherent empty state when user has no departments', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myDepartmentsByUnitProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: MyDepartmentsMenuScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Você ainda não participa de nenhum departamento.'),
      findsOneWidget,
    );
  });

  testWidgets('navigates to department detail from menu flow list', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.homeMenuMyDepartments,
      routes: [
        GoRoute(
          path: AppRoutes.homeMenuMyDepartments,
          builder: (context, state) => const MyDepartmentsMenuScreen(),
        ),
        GoRoute(
          path: AppRoutes.homeChurchDepartmentDetail,
          name: AppRoutes.homeChurchDepartmentDetailName,
          builder: (context, state) =>
              const Scaffold(body: Text('detail-shell')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myDepartmentsByUnitProvider.overrideWith(
            (ref) async => const [
              MyDepartmentsUnitGroup(
                unitId: 'unit-1',
                unitName: 'Igreja Batista Betel',
                departments: [_louvorDepartment],
              ),
            ],
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
