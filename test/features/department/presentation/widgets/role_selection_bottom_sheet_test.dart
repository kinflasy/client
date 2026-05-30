import 'dart:async';

import 'package:client/features/department/data/models/role_request_model.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/widgets/role_selection_bottom_sheet.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/core/errors/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _FakeRoleRequestModel extends Fake implements RoleRequestModel {}

void main() {
  late _MockDepartmentRepository repository;
  late List<RoleEntity> selectedRoles;

  setUpAll(() {
    registerFallbackValue(_FakeRoleRequestModel());
  });

  setUp(() {
    repository = _MockDepartmentRepository();
    selectedRoles = [];
  });

  testWidgets('shows loading state', (tester) async {
    final completer = Completer<Either<Failure, List<RoleEntity>>>();
    when(() => repository.getRoles()).thenAnswer((_) => completer.future);

    await _pumpHost(
      tester,
      repository: repository,
      selectedRoles: selectedRoles,
    );
    await _openSheet(tester);

    expect(find.byKey(const Key('role-loading-placeholder')), findsWidgets);
  });

  testWidgets('shows empty and search without result states', (tester) async {
    _stubRoles(repository, const []);

    await _pumpHost(
      tester,
      repository: repository,
      selectedRoles: selectedRoles,
    );
    await _openSheet(tester);

    expect(find.text('Nenhum papel encontrado'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'teclado');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum papel encontrado para "teclado"'), findsOneWidget);
  });

  testWidgets('local search ignores accents and letter case', (tester) async {
    _stubRoles(repository, const [
      RoleEntity(id: 'role-1', name: 'Violão', slug: 'violao'),
    ]);

    await _pumpHost(
      tester,
      repository: repository,
      selectedRoles: selectedRoles,
    );
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField), 'VIOLAO');
    await tester.pumpAndSettle();

    expect(find.text('Violão'), findsOneWidget);
  });

  testWidgets('create row appears only when there is no exact match', (
    tester,
  ) async {
    _stubRoles(repository, const [
      RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
    ]);

    await _pumpHost(
      tester,
      repository: repository,
      selectedRoles: selectedRoles,
    );
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField), 'vocal');
    await tester.pumpAndSettle();

    expect(find.text('Criar papel "vocal"'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Baixo');
    await tester.pumpAndSettle();

    expect(find.text('Criar papel "Baixo"'), findsOneWidget);
  });

  testWidgets('creating role selects it and keeps sheet open', (tester) async {
    _stubRoles(repository, const [
      RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
    ]);
    when(() => repository.createRole(any())).thenAnswer(
      (_) async =>
          const Right(RoleEntity(id: 'role-2', name: 'Baixo', slug: 'baixo')),
    );

    await _pumpHost(
      tester,
      repository: repository,
      selectedRoles: selectedRoles,
    );
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField), 'Baixo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar papel "Baixo"'));
    await tester.pumpAndSettle();

    verify(() => repository.createRole(any())).called(1);
    expect(selectedRoles.single.name, 'Baixo');
    expect(find.text('Selecionar papel'), findsOneWidget);
  });

  testWidgets('plus button selects role and keeps sheet open', (tester) async {
    _stubRoles(repository, const [
      RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
    ]);

    await _pumpHost(
      tester,
      repository: repository,
      selectedRoles: selectedRoles,
    );
    await _openSheet(tester);

    expect(find.text('-'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();

    expect(selectedRoles.single.name, 'Vocal');
    expect(find.text('1 na formação'), findsOneWidget);
    expect(find.text('Selecionar papel'), findsOneWidget);
  });

  testWidgets('counter shows one, two and dash correctly', (tester) async {
    _stubRoles(repository, const [
      RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
      RoleEntity(id: 'role-2', name: 'Bateria', slug: 'bateria'),
    ]);

    await _pumpHost(
      tester,
      repository: repository,
      selectedRoles: selectedRoles,
      selectedRoleCounts: const {'role-1': 1},
    );
    await _openSheet(tester);

    expect(find.text('1 na formação'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text('2 na formação'), findsOneWidget);
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required DepartmentRepository repository,
  required List<RoleEntity> selectedRoles,
  Map<String, int> selectedRoleCounts = const {},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [departmentRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showRoleSelectionBottomSheet(
                  context: context,
                  selectedRoleCounts: selectedRoleCounts,
                  onSelect: selectedRoles.add,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void _stubRoles(_MockDepartmentRepository repository, List<RoleEntity> roles) {
  when(() => repository.getRoles()).thenAnswer((_) async => Right(roles));
}
