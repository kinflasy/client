import 'dart:async';

import 'package:client/core/address/address_value.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/presentation/screens/logged_user_profile_screen.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _profileStateProvider = StateProvider<LoggedUserProfileEntity>(
  (ref) => _fullProfile(),
);

void main() {
  Widget buildApp({
    required Future<LoggedUserProfileEntity> Function() loadProfile,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.homeMenuEditProfile,
      routes: [
        GoRoute(
          path: AppRoutes.homeMenu,
          builder: (context, state) => const Scaffold(body: Text('Menu')),
        ),
        GoRoute(
          path: AppRoutes.homeMenuEditProfile,
          name: AppRoutes.homeMenuEditProfileName,
          builder: (context, state) => const LoggedUserProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.homeMenuEditProfileInfo,
          name: AppRoutes.homeMenuEditProfileInfoName,
          builder: (context, state) =>
              const Scaffold(body: Text('Tela de edição de dados pessoais')),
        ),
        GoRoute(
          path: AppRoutes.homeMenuEditProfileAddress,
          name: AppRoutes.homeMenuEditProfileAddressName,
          builder: (context, state) =>
              const Scaffold(body: Text('Tela de edição de endereço')),
        ),
        GoRoute(
          path: AppRoutes.homeMenuEditProfilePhoto,
          name: AppRoutes.homeMenuEditProfilePhotoName,
          builder: (context, state) =>
              const Scaffold(body: Text('Tela de edição de foto')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        editLoggedUserInitialDataProvider.overrideWith((ref) => loadProfile()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('cobre loading', (tester) async {
    final completer = Completer<LoggedUserProfileEntity>();

    await tester.pumpWidget(buildApp(loadProfile: () => completer.future));
    await tester.pump();

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('cobre erro e retry', (tester) async {
    final firstAttempt = Completer<LoggedUserProfileEntity>();
    var allowSuccess = false;

    await tester.pumpWidget(
      buildApp(
        loadProfile: () {
          return allowSuccess
              ? Future.value(_fullProfile())
              : firstAttempt.future;
        },
      ),
    );
    await tester.pump();

    firstAttempt.completeError(Exception('Falha ao carregar perfil.'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Tentar novamente'), findsOneWidget);

    allowSuccess = true;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Lisa Silva'), findsWidgets);
  });

  testWidgets('cobre dados completos', (tester) async {
    await tester.pumpWidget(buildApp(loadProfile: () async => _fullProfile()));
    await tester.pump();

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Resumo'), findsOneWidget);
    expect(find.text('Lisa Silva'), findsWidgets);
    expect(find.text('Li'), findsWidgets);
    expect(find.text('Feminino'), findsOneWidget);
    expect(find.text('09/04/1998'), findsOneWidget);
    expect(find.text(_ageLabel(DateTime(1998, 4, 9))), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Contato'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Contato'), findsOneWidget);
    expect(find.text('(85) 99999-1111'), findsOneWidget);
    expect(find.text('lisa@example.com'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Rua Alfa'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(
      find.textContaining('Rua Alfa, 123, Centro, Fortaleza, CE, Brasil'),
      findsOneWidget,
    );
  });

  testWidgets('cobre dados parciais e ausência de endereço', (tester) async {
    await tester.pumpWidget(
      buildApp(loadProfile: () async => _partialProfile()),
    );
    await tester.pump();

    expect(find.text('Usuário'), findsWidgets);
    expect(find.text('Não informado'), findsAtLeastNWidgets(4));
    await tester.scrollUntilVisible(
      find.text('Endereço não informado'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Endereço não informado'), findsOneWidget);
    expect(find.text('null'), findsNothing);
  });

  testWidgets('confirma botões de dados pessoais, endereço e foto', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(loadProfile: () async => _fullProfile()));
    await tester.pump();

    expect(find.text('Editar foto'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Editar dados pessoais'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Editar dados pessoais'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Editar endereço'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Editar endereço'), findsOneWidget);
  });

  testWidgets('navega para edição de dados pessoais', (tester) async {
    await tester.pumpWidget(buildApp(loadProfile: () async => _fullProfile()));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Editar dados pessoais'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Editar dados pessoais'));
    await tester.pumpAndSettle();
    expect(find.text('Tela de edição de dados pessoais'), findsOneWidget);
  });

  testWidgets('navega para edição de endereço', (tester) async {
    await tester.pumpWidget(buildApp(loadProfile: () async => _fullProfile()));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Editar endereço'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Editar endereço'));
    await tester.pumpAndSettle();

    expect(find.text('Tela de edição de endereço'), findsOneWidget);
  });

  testWidgets('navega para edição de foto', (tester) async {
    await tester.pumpWidget(buildApp(loadProfile: () async => _fullProfile()));
    await tester.pump();

    await tester.tap(find.text('Editar foto'));
    await tester.pumpAndSettle();

    expect(find.text('Tela de edição de foto'), findsOneWidget);
  });

  testWidgets('avatar do resumo muda quando o provider atualiza', (
    tester,
  ) async {
    final resolvedImageIds = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _profileStateProvider.overrideWith(
            (ref) => _fullProfile(profileImageId: 'old-image'),
          ),
          editLoggedUserInitialDataProvider.overrideWith(
            (ref) async => ref.watch(_profileStateProvider),
          ),
          mediaImageUrlProvider.overrideWith((ref, imageId) async {
            resolvedImageIds.add(imageId);
            return 'https://cdn.example/$imageId.png';
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              return Scaffold(
                body: Column(
                  children: [
                    FilledButton(
                      onPressed: () {
                        ref.read(_profileStateProvider.notifier).state =
                            _fullProfile(profileImageId: 'new-image');
                      },
                      child: const Text('Atualizar foto'),
                    ),
                    const Expanded(child: LoggedUserProfileScreen()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(resolvedImageIds, contains('old-image'));

    await tester.tap(find.text('Atualizar foto'));
    await tester.pump();
    await tester.pump();

    expect(resolvedImageIds, contains('new-image'));
  });
}

LoggedUserProfileEntity _fullProfile({String? profileImageId}) {
  return LoggedUserProfileEntity(
    id: 'user-1',
    fullName: 'Lisa Silva',
    nickname: 'Li',
    gender: 'FEMALE',
    birthDate: DateTime(1998, 4, 9),
    phone: '85999991111',
    email: 'lisa@example.com',
    address: const AddressValue(
      zip: '60000-000',
      country: 'Brasil',
      state: 'CE',
      city: 'Fortaleza',
      neighborhood: 'Centro',
      street: 'Rua Alfa',
      number: '123',
      complement: 'Apto 4',
    ),
    profileImageId: profileImageId,
  );
}

LoggedUserProfileEntity _partialProfile() {
  return const LoggedUserProfileEntity(id: 'user-1', fullName: '', gender: '');
}

String _ageLabel(DateTime birthDate) {
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }

  return '$age anos';
}
