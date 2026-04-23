import 'dart:async';

import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/menu/presentation/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  const user = UserEntity(
    id: 'user-1',
    username: 'lisa',
    fullName: 'Lisa Silva',
    nickname: 'Lisa',
    email: 'lisa@example.com',
  );

  Widget buildApp({AuthRepository? authRepository, bool hasMembership = true}) {
    final router = GoRouter(
      initialLocation: AppRoutes.homeMenu,
      routes: [
        GoRoute(
          path: AppRoutes.homeMenu,
          name: AppRoutes.homeMenuName,
          builder: (context, state) => const MenuScreen(),
        ),
        GoRoute(
          path: AppRoutes.homeMenuEditProfile,
          name: AppRoutes.homeMenuEditProfileName,
          builder: (context, state) =>
              const Scaffold(body: Text('Editar perfil')),
        ),
        GoRoute(
          path: AppRoutes.registerChurch,
          name: AppRoutes.registerChurchName,
          builder: (context, state) =>
              const Scaffold(body: Text('Register church')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository ?? repository),
        hasMembershipProvider.overrideWith((ref) => hasMembership),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);
    when(() => repository.signOut()).thenAnswer((_) async => const Right(null));
  });

  Future<void> scrollToText(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the menu in PT-BR with updated sections', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Lisa'), findsOneWidget);
    expect(find.text('Notificações'), findsNothing);
    expect(find.text('Editar informações'), findsNothing);
    expect(find.text('Minhas igrejas'), findsNothing);
    expect(find.text('Configurações'), findsNothing);
    expect(find.text('Minha conta'), findsOneWidget);
    expect(find.text('Outros'), findsOneWidget);
    expect(find.text('Cadastrar igreja'), findsOneWidget);
    expect(find.text('Central de ajuda'), findsOneWidget);
    expect(find.text('Termos de uso'), findsOneWidget);
    expect(find.text('Seu espaço no Pontis'), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.church_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('shows loading placeholder for the user header', (tester) async {
    final completer = Completer<UserEntity?>();
    when(() => repository.getCurrentUser()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('Usuário'), findsNothing);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.text('Minha conta'), findsOneWidget);
  });

  testWidgets('falls back safely when auth loading fails', (tester) async {
    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) => Future<UserEntity?>.error(Exception('boom')));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Minha conta'), findsOneWidget);
    expect(find.text('Outros'), findsOneWidget);
  });

  testWidgets(
    'keeps Meus departamentos visible and disabled without membership',
    (tester) async {
      await tester.pumpWidget(buildApp(hasMembership: false));
      await tester.pumpAndSettle();

      expect(find.text('Meus departamentos'), findsOneWidget);

      final inkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Meus departamentos'),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.onTap, isNull);
    },
  );

  testWidgets('navigates to register church screen', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar igreja'));
    await tester.pumpAndSettle();

    expect(find.text('Register church'), findsOneWidget);
  });

  testWidgets('navigates to edit logged user screen from quick action', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Editar perfil'), findsOneWidget);
  });

  testWidgets('confirms and signs out', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Sair');
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(
      find.text('Tem certeza que deseja sair da sua conta?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();

    verify(() => repository.signOut()).called(1);
  });
}
