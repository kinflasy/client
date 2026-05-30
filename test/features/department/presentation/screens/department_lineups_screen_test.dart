import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/presentation/screens/department_lineups_screen.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _leaderPermissions = SessionPermissions(
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
      integrationType: IntegrationType.leader,
    ),
  ],
  isUnitAdmin: false,
);

const _integrantPermissions = SessionPermissions(
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
);

void main() {
  testWidgets('shows loading state', (tester) async {
    final completer = Completer<List<LineupEntity>>();

    await _pumpScreen(tester, lineupsBuilder: (ref) => completer.future);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error state', (tester) async {
    await _pumpScreen(
      tester,
      lineupsBuilder: (ref) => Future.error(Exception('falha')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar as formações de escala.'),
      findsOneWidget,
    );
    expect(find.text('Tente novamente em instantes.'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    await _pumpScreen(tester, lineups: const []);
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma formação de escala criada ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('shows create button only for department manager', (
    tester,
  ) async {
    await _pumpScreen(tester, lineups: const []);
    await tester.pumpAndSettle();

    expect(find.text('Criar nova formação de escala'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await _pumpScreen(
      tester,
      permissions: _integrantPermissions,
      lineups: const [],
    );
    await tester.pumpAndSettle();

    expect(find.text('Criar nova formação de escala'), findsNothing);
  });

  testWidgets('shows lineup cards with title and role summary', (tester) async {
    await _pumpScreen(tester, lineups: [_lineupWithRoles]);
    await tester.pumpAndSettle();

    expect(find.text('Louvor - Culto dominical'), findsOneWidget);
    expect(find.textContaining('4 papéis'), findsOneWidget);
    expect(find.textContaining('Vocal'), findsOneWidget);
    expect(find.textContaining('Guitarra'), findsOneWidget);
    expect(find.textContaining('Bateria'), findsOneWidget);
    expect(find.textContaining('+1'), findsOneWidget);
  });

  testWidgets('uses singular role count label', (tester) async {
    await _pumpScreen(
      tester,
      lineups: const [
        LineupEntity(
          id: 'lineup-2',
          name: 'Recepção',
          items: [
            LineupItemEntity(
              id: 'item-1',
              lineupId: 'lineup-2',
              roleId: 'role-1',
              description: 'Recepcionista',
            ),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1 papel'), findsOneWidget);
  });

  testWidgets('create button navigates to create route', (tester) async {
    final router = _buildRouter(lineups: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionPermissionsProvider.overrideWith(
            (ref) async => _leaderPermissions,
          ),
          departmentLineupsProvider(
            'dep-1',
          ).overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar nova formação de escala'));
    await tester.pumpAndSettle();

    expect(find.text('Destino de criação'), findsOneWidget);
  });

  testWidgets('lineup card navigates to detail route', (tester) async {
    final router = _buildRouter(lineups: const [_lineupWithRoles]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionPermissionsProvider.overrideWith(
            (ref) async => _leaderPermissions,
          ),
          departmentLineupsProvider(
            'dep-1',
          ).overrideWith((ref) async => const [_lineupWithRoles]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Louvor - Culto dominical'));
    await tester.pumpAndSettle();

    expect(find.text('Destino de detalhe'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  SessionPermissions permissions = _leaderPermissions,
  List<LineupEntity>? lineups,
  Future<List<LineupEntity>> Function(Ref ref)? lineupsBuilder,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
        departmentLineupsProvider(
          'dep-1',
        ).overrideWith(lineupsBuilder ?? (ref) async => lineups ?? const []),
      ],
      child: const MaterialApp(
        home: DepartmentLineupsScreen(departmentId: 'dep-1'),
      ),
    ),
  );
}

const _lineupWithRoles = LineupEntity(
  id: 'lineup-1',
  name: 'Louvor - Culto dominical',
  items: [
    LineupItemEntity(
      id: 'item-1',
      lineupId: 'lineup-1',
      roleId: 'role-1',
      description: 'Vocal',
      role: RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
    ),
    LineupItemEntity(
      id: 'item-2',
      lineupId: 'lineup-1',
      roleId: 'role-2',
      description: 'Guitarra',
      role: RoleEntity(id: 'role-2', name: 'Guitarra', slug: 'guitarra'),
    ),
    LineupItemEntity(
      id: 'item-3',
      lineupId: 'lineup-1',
      roleId: 'role-3',
      description: 'Bateria',
      role: RoleEntity(id: 'role-3', name: 'Bateria', slug: 'bateria'),
    ),
    LineupItemEntity(
      id: 'item-4',
      lineupId: 'lineup-1',
      roleId: 'role-4',
      description: 'Baixo',
      role: RoleEntity(id: 'role-4', name: 'Baixo', slug: 'baixo'),
    ),
  ],
);

GoRouter _buildRouter({required List<LineupEntity> lineups}) {
  return GoRouter(
    initialLocation: '/departamentos/dep-1/formacoes-de-escala',
    routes: [
      GoRoute(
        path: AppRoutes.departmentScaleFormations,
        name: AppRoutes.departmentScaleFormationsName,
        builder: (context, state) =>
            DepartmentLineupsScreen(departmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.departmentScaleFormationCreate,
        name: AppRoutes.departmentScaleFormationCreateName,
        builder: (context, state) =>
            const Scaffold(body: Text('Destino de criação')),
      ),
      GoRoute(
        path: AppRoutes.departmentScaleFormationDetail,
        name: AppRoutes.departmentScaleFormationDetailName,
        builder: (context, state) =>
            const Scaffold(body: Text('Destino de detalhe')),
      ),
    ],
  );
}
