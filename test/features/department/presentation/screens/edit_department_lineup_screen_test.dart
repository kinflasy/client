import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/screens/edit_department_lineup_screen.dart';
import 'package:client/features/department/providers/department_providers.dart';
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

  testWidgets('create lineup without name shows inline error', (tester) async {
    await _pumpScreen(tester, repository: repository);

    expect(find.widgetWithText(TextButton, 'Salvar'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Salvar'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), ' ');
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do lineup.'), findsOneWidget);
  });

  testWidgets('save button enables only with filled name', (tester) async {
    await _pumpScreen(tester, repository: repository);

    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Salvar'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextFormField), 'Louvor');
    await tester.pump();

    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Salvar'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('add role opens sheet and same role can appear more than once', (
    tester,
  ) async {
    await _pumpScreen(tester, repository: repository);

    await tester.tap(find.text('Adicionar papel'));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar papel'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pump();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pump();

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    expect(find.text('Bateria'), findsNWidgets(2));
  });

  testWidgets('removing one duplicate keeps the other', (tester) async {
    await _pumpScreen(tester, repository: repository);

    await _addFirstRoleTwice(tester);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('Bateria'), findsNWidgets(1));
  });

  testWidgets('saving without roles creates only lineup', (tester) async {
    final router = await _pumpScreen(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'Louvor');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/done');
    verify(
      () => repository.createDepartmentLineup(
        'dep-1',
        any(that: isA<LineupRequestModel>()),
      ),
    ).called(1);
    verifyNever(() => repository.createLineupItem(any(), any()));
  });

  testWidgets('saving with roles creates lineup and items', (tester) async {
    final router = await _pumpScreen(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'Louvor');
    await _addFirstRoleTwice(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/done');
    verify(() => repository.createDepartmentLineup('dep-1', any())).called(1);
    verify(
      () => repository.createLineupItem('lineup-created', any()),
    ).called(2);
  });

  testWidgets('editing loads existing items and removes one duplicated item', (
    tester,
  ) async {
    when(
      () => repository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(_existingLineup));

    final router = await _pumpScreen(
      tester,
      repository: repository,
      lineupId: 'lineup-1',
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar lineup'), findsOneWidget);
    expect(find.text('Vocal'), findsNWidgets(2));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.close).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/done');
    verify(() => repository.updateLineup('lineup-1', any())).called(1);
    verify(() => repository.deleteLineupItem('item-1')).called(1);
  });

  testWidgets('remove lineup asks confirmation and returns after success', (
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

    await tester.tap(find.byTooltip('Remover escala'));
    await tester.pumpAndSettle();

    expect(find.text('Remover escala?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/done');
    verify(() => repository.deleteLineup('lineup-1')).called(1);
  });

  testWidgets('remove lineup error keeps user on edit screen', (tester) async {
    when(
      () => repository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(_existingLineup));
    when(
      () => repository.deleteLineup('lineup-1'),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha')));

    await _pumpScreen(tester, repository: repository, lineupId: 'lineup-1');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remover escala'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(find.text('Editar lineup'), findsOneWidget);
    expect(find.text('Não foi possível remover a escala.'), findsOneWidget);
  });

  testWidgets('back with changes shows confirmation', (tester) async {
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

  testWidgets('save error keeps filled data on screen', (tester) async {
    when(
      () => repository.createDepartmentLineup(any(), any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha')));

    await _pumpScreen(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField), 'Louvor');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Não foi possível salvar o lineup.'), findsOneWidget);
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
      overrides: [departmentRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push('/edit');
  await tester.pumpAndSettle();
  return router;
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

const _createdLineup = LineupEntity(id: 'lineup-created', name: 'Louvor');

const _createdItem = LineupItemEntity(
  id: 'item-created',
  lineupId: 'lineup-created',
  roleId: 'role-1',
  description: 'Vocal',
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
