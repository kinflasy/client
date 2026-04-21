import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/screens/register_department_screen.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

void main() {
  late _MockDepartmentRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const DepartmentRequestModel(
        name: 'fallback',
        slug: 'fallback',
        type: 'MINISTRY',
      ),
    );
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/departments',
      routes: [
        GoRoute(
          path: '/departments',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/register-department'),
                child: const Text('open register'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/register-department',
          builder: (context, state) => const RegisterDepartmentScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  setUp(() {
    repository = _MockDepartmentRepository();
  });

  Future<void> selectType(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('validates required fields before submitting', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('open register'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Campo obrigatorio'), findsNWidgets(3));
    verifyNever(() => repository.createDepartment(any(), any()));
  });

  testWidgets('fills slug automatically from name and submits it on success', (
    tester,
  ) async {
    when(() => repository.createDepartment('unit-1', any())).thenAnswer(
      (_) async => const Right(
        DepartmentEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('open register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Louvor');
    await tester.pumpAndSettle();

    expect(find.text('Preview do slug: @louvor'), findsOneWidget);
    await selectType(tester, 'Departamento');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final captured =
        verify(
              () => repository.createDepartment('unit-1', captureAny()),
            ).captured.single
            as DepartmentRequestModel;
    expect(captured.name, 'Louvor');
    expect(captured.slug, 'louvor');
    expect(captured.type, 'MINISTRY');
    expect(find.text('open register'), findsOneWidget);
  });

  testWidgets('keeps manual slug after user edits it', (tester) async {
    when(() => repository.createDepartment('unit-1', any())).thenAnswer(
      (_) async => const Right(
        DepartmentEntity(
          id: 'dep-1',
          name: 'Ministerio Infantil',
          slug: 'kids-pontis',
          type: 'MINISTRY',
        ),
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('open register'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Ministerio Infantil',
    );
    await tester.pumpAndSettle();
    expect(find.text('Preview do slug: @ministerio-infantil'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'Kids Pontis');
    await tester.pumpAndSettle();
    expect(find.text('Preview do slug: @kids-pontis'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Ministerio Infantil Oficial',
    );
    await tester.pumpAndSettle();
    expect(find.text('Preview do slug: @kids-pontis'), findsOneWidget);

    await selectType(tester, 'Departamento');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final captured =
        verify(
              () => repository.createDepartment('unit-1', captureAny()),
            ).captured.single
            as DepartmentRequestModel;
    expect(captured.slug, 'kids-pontis');
  });

  testWidgets('blocks submit when slug becomes empty after normalization', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('open register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Louvor');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '!!!');
    await tester.pumpAndSettle();
    await selectType(tester, 'Departamento');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Campo obrigatorio'), findsOneWidget);
    verifyNever(() => repository.createDepartment(any(), any()));
  });

  testWidgets('shows backend error and stays on form when submit fails', (
    tester,
  ) async {
    when(() => repository.createDepartment('unit-1', any())).thenAnswer(
      (_) async => const Left(ValidationFailure('Slug ja cadastrado')),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('open register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Louvor');
    await tester.pumpAndSettle();
    await selectType(tester, 'Departamento');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Slug ja cadastrado'), findsOneWidget);
    expect(find.text('Cadastrar departamento'), findsOneWidget);
  });
}
