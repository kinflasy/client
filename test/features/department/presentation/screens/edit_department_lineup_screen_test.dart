import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/screens/edit_department_lineup_screen.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _FakeLineupRequestModel extends Fake implements LineupRequestModel {}

class _FakeLineupItemRequestModel extends Fake
    implements LineupItemRequestModel {}

void main() {
  late _MockDepartmentRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeLineupRequestModel());
    registerFallbackValue(_FakeLineupItemRequestModel());
  });

  setUp(() {
    repository = _MockDepartmentRepository();
    _stubRoles(repository);
    when(
      () => repository.createDepartmentLineup(any(), any()),
    ).thenAnswer((_) async => const Right(_createdLineup));
    when(
      () => repository.updateLineup(any(), any()),
    ).thenAnswer((_) async => const Right(_existingLineup));
    when(
      () => repository.createLineupItem(any(), any()),
    ).thenAnswer((_) async => const Right(_createdItem));
    when(
      () => repository.deleteLineupItem(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  testWidgets('create state hides roles until lineup is created', (
    tester,
  ) async {
    await _pumpScreen(tester, repository: repository);

    expect(find.widgetWithText(FilledButton, 'Criar'), findsOneWidget);
    expect(find.text('Papéis'), findsNothing);
    expect(find.text('Adicionar papel'), findsNothing);
  });

  testWidgets('create lineup without name shows inline error', (tester) async {
    await _pumpScreen(tester, repository: repository);

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Criar'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), ' ');
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do lineup.'), findsOneWidget);
  });

  testWidgets('create button enables only with filled name', (tester) async {
    await _pumpScreen(tester, repository: repository);

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Criar'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextFormField), 'Louvor');
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Criar'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('creating lineup freezes name and shows roles section', (
    tester,
  ) async {
    await _pumpScreen(tester, repository: repository);

    await _createLineup(tester);

    expect(find.widgetWithText(FilledButton, 'Editar nome'), findsOneWidget);
    expect(find.text('Papéis'), findsOneWidget);
    expect(find.text('Adicionar papel'), findsOneWidget);
    expect(find.text('Salvar papéis'), findsOneWidget);
    verify(() => repository.createDepartmentLineup('dep-1', any())).called(1);
    verifyNever(() => repository.createLineupItem(any(), any()));
  });

  testWidgets('editing created lineup name calls only update lineup', (
    tester,
  ) async {
    await _pumpScreen(tester, repository: repository);
    await _createLineup(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Editar nome'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'Louvor atualizado');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    verify(() => repository.updateLineup('lineup-created', any())).called(1);
    verifyNever(() => repository.createLineupItem(any(), any()));
  });

  testWidgets(
    'adding and removing roles before saving does not call item APIs',
    (tester) async {
      await _pumpScreen(tester, repository: repository);
      await _createLineup(tester);

      await _addFirstRoleTwice(tester);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Bateria'), findsNWidgets(1));
      verifyNever(() => repository.createLineupItem(any(), any()));
      verifyNever(() => repository.deleteLineupItem(any()));
    },
  );

  testWidgets('saving roles creates one item per local slot', (tester) async {
    final router = await _pumpScreen(tester, repository: repository);
    await _createLineup(tester);
    await _addFirstRoleTwice(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar papéis'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/done');
    verify(() => repository.createDepartmentLineup('dep-1', any())).called(1);
    verify(
      () => repository.createLineupItem('lineup-created', any()),
    ).called(2);
  });

  testWidgets('saving empty roles returns without creating item', (
    tester,
  ) async {
    final router = await _pumpScreen(tester, repository: repository);
    await _createLineup(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar papéis'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/done');
    verifyNever(() => repository.createLineupItem(any(), any()));
  });

  testWidgets('detail app bar shows lineup name', (tester) async {
    when(
      () => repository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(_existingLineup));

    await _pumpScreen(tester, repository: repository, lineupId: 'lineup-1');
    await tester.pumpAndSettle();

    expect(find.text('Culto'), findsWidgets);
    expect(find.text('Editar lineup'), findsNothing);
    expect(find.text('Vocal'), findsNWidgets(2));
  });

  testWidgets('detail edit name and save calls update lineup', (tester) async {
    when(
      () => repository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(_existingLineup));

    await _pumpScreen(tester, repository: repository, lineupId: 'lineup-1');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Editar nome'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'Culto atualizado');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    verify(() => repository.updateLineup('lineup-1', any())).called(1);
  });

  testWidgets('detail adding role persists immediately', (tester) async {
    when(
      () => repository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(_existingLineup));

    await _pumpScreen(tester, repository: repository, lineupId: 'lineup-1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar papel'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pumpAndSettle();

    verify(() => repository.createLineupItem('lineup-1', any())).called(1);
  });

  testWidgets('detail removing role asks confirmation and deletes item', (
    tester,
  ) async {
    when(
      () => repository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(_existingLineup));

    await _pumpScreen(tester, repository: repository, lineupId: 'lineup-1');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('Remover papel?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Remover'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteLineupItem('item-1')).called(1);
  });

  testWidgets('remove lineup lives in menu and returns after success', (
    tester,
  ) async {
    when(
      () => repository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(_existingLineup));
    when(
      () => repository.deleteLineup('lineup-1'),
    ).thenAnswer((_) async => const Right(unit));

    final router = await _pumpScreen(
      tester,
      repository: repository,
      lineupId: 'lineup-1',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover escala'));
    await tester.pumpAndSettle();

    expect(find.text('Remover escala?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/done');
    verify(() => repository.deleteLineup('lineup-1')).called(1);
  });

  testWidgets('remove lineup error keeps user on detail screen', (
    tester,
  ) async {
    when(
      () => repository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(_existingLineup));
    when(
      () => repository.deleteLineup('lineup-1'),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha')));

    await _pumpScreen(tester, repository: repository, lineupId: 'lineup-1');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover escala'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(find.text('Culto'), findsWidgets);
    expect(find.text('Não foi possível remover a escala.'), findsOneWidget);
  });

  testWidgets('back with name changes shows confirmation', (tester) async {
    await _pumpScreen(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'Louvor');
    await tester.pump();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsOneWidget);
    expect(
      find.text('Existem alterações não salvas. Deseja sair mesmo assim?'),
      findsOneWidget,
    );
  });

  testWidgets('create error keeps filled data on screen', (tester) async {
    when(
      () => repository.createDepartmentLineup(any(), any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha')));

    await _pumpScreen(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'Louvor');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Não foi possível criar o lineup.'), findsOneWidget);
  });
}

Future<GoRouter> _pumpScreen(
  WidgetTester tester, {
  required DepartmentRepository repository,
  String? lineupId,
}) async {
  final router = GoRouter(
    initialLocation: '/done',
    routes: [
      GoRoute(
        path: '/edit',
        builder: (context, state) => EditDepartmentLineupScreen(
          departmentId: 'dep-1',
          lineupId: lineupId,
        ),
      ),
      GoRoute(
        path: '/done',
        builder: (context, state) => const Scaffold(body: Text('Pronto')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
        sessionPermissionsProvider.overrideWith(
          (ref) async => _leaderPermissions,
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push('/edit');
  await tester.pumpAndSettle();
  return router;
}

Future<void> _createLineup(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField), 'Louvor');
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
  await tester.pumpAndSettle();
}

Future<void> _addFirstRoleTwice(WidgetTester tester) async {
  await tester.tap(find.text('Adicionar papel'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
  await tester.pump();
  await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
  await tester.pump();
  await tester.tap(find.byTooltip('Fechar'));
  await tester.pumpAndSettle();
}

void _stubRoles(DepartmentRepository repository) {
  when(() => repository.getRoles()).thenAnswer(
    (_) async => const Right([
      RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
      RoleEntity(id: 'role-2', name: 'Bateria', slug: 'bateria'),
    ]),
  );
}

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

const _createdLineup = LineupEntity(id: 'lineup-created', name: 'Louvor');

const _createdItem = LineupItemEntity(
  id: 'item-created',
  lineupId: 'lineup-1',
  roleId: 'role-1',
  description: 'Vocal',
  role: RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
);

const _existingLineup = LineupEntity(
  id: 'lineup-1',
  name: 'Culto',
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
      roleId: 'role-1',
      description: 'Vocal',
      role: RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
    ),
  ],
);
