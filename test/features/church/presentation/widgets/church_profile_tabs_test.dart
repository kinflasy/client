import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/presentation/widgets/church_profile_tabs.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('navigates from church departments tab to shell detail route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.homeChurch,
      routes: [
        GoRoute(
          path: AppRoutes.homeChurch,
          builder: (context, state) =>
              const Scaffold(body: DepartmentsTab(unitId: 'unit-1')),
          routes: [
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
          departmentsProvider.overrideWith(
            (ref, unitId) async => const [
              DepartmentEntity(
                id: 'dep-1',
                name: 'Louvor',
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

    await tester.tap(find.text('Louvor'));
    await tester.pumpAndSettle();

    expect(find.text('detail-shell'), findsOneWidget);
  });
}
