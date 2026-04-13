import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(DateTime(1998, 4, 9));
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: AppRoutes.register,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
  });

  Future<void> scrollToSubmit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.pumpAndSettle();
  }

  Future<void> selectGender(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('renders gender and birth date fields', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Gênero *'), findsOneWidget);
    expect(find.text('Data de nascimento *'), findsOneWidget);
    expect(find.text('DD/MM/AAAA'), findsOneWidget);
  });

  testWidgets('blocks submit when gender is missing', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome completo *'),
      'Lisa Silva',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Usuário *'), 'lisa');
    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail *'),
      'lisa@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Data de nascimento *'),
      '09/04/1998',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Senha *'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirmar senha *'),
      'secret1',
    );

    await scrollToSubmit(tester);
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    verifyNever(
      () => repository.signUp(
        name: any(named: 'name'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
        birthDate: any(named: 'birthDate'),
      ),
    );
  });

  testWidgets('blocks submit when birth date is invalid', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome completo *'),
      'Lisa Silva',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Usuário *'), 'lisa');
    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail *'),
      'lisa@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Data de nascimento *'),
      '32/13/2025',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Senha *'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirmar senha *'),
      'secret1',
    );

    await selectGender(tester, 'Masculino');

    await scrollToSubmit(tester);
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    verifyNever(
      () => repository.signUp(
        name: any(named: 'name'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
        birthDate: any(named: 'birthDate'),
      ),
    );
  });

  testWidgets('submits typed valid birth date', (tester) async {
    when(
      () => repository.signUp(
        name: any(named: 'name'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        gender: any(named: 'gender'),
        birthDate: any(named: 'birthDate'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        UserEntity(
          id: 'user-1',
          username: 'lisa',
          fullName: 'Lisa Silva',
          email: 'lisa@example.com',
        ),
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome completo *'),
      'Lisa Silva',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Usuário *'), 'lisa');
    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail *'),
      'lisa@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Data de nascimento *'),
      '09041998',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Senha *'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirmar senha *'),
      'secret1',
    );

    await selectGender(tester, 'Feminino');

    expect(find.text('09/04/1998'), findsOneWidget);

    await scrollToSubmit(tester);
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();

    verify(
      () => repository.signUp(
        name: 'Lisa Silva',
        username: 'lisa',
        email: 'lisa@example.com',
        password: 'secret1',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
      ),
    ).called(1);
  });

  testWidgets('opens date picker and writes selected date', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(TextField, 'Data de nascimento *'),
      findsOneWidget,
    );
  });
}
