import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/screens/department_screen.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

void main() {
  late _MockDepartmentRepository repository;

  setUp(() {
    repository = _MockDepartmentRepository();
  });

  testWidgets('shows detail tabs and switches to participants list', (
    tester,
  ) async {
    when(() => repository.getDepartmentById('dep-1')).thenAnswer(
      (_) async => const Right(
        DepartmentDetailEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
      ),
    );
    when(() => repository.getParticipants('dep-1')).thenAnswer(
      (_) async => const Right([
        DepartmentParticipantEntity(
          personId: 'person-1',
          fullName: 'Maria Silva',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
          age: 34,
        ),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [departmentRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: DepartmentScreen(
            departmentId: 'dep-1',
            showBackButton: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Participantes'), findsOneWidget);
    expect(find.text('Eventos do departamento em breve.'), findsOneWidget);

    await tester.tap(find.text('Participantes'));
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Membros · 34 anos'), findsOneWidget);
  });

  testWidgets('shows inline error when department detail fails', (tester) async {
    when(() => repository.getDepartmentById('dep-1')).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao carregar departamento')),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [departmentRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: DepartmentScreen(
            departmentId: 'dep-1',
            showBackButton: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Departamento'), findsOneWidget);
    expect(
      find.text('Nao foi possivel carregar o departamento.'),
      findsOneWidget,
    );
    expect(find.text('Participantes'), findsNothing);
  });
}
