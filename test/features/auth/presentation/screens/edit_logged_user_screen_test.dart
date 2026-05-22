import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/edit_logged_user_screen.dart';
import 'package:client/features/auth/presentation/screens/logged_user_profile_screen.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toastification/toastification.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockDio extends Mock implements Dio {}

class _FakeUpdateLoggedUserRequestModel extends Fake
    implements UpdateLoggedUserRequestModel {}

void main() {
  late _MockAuthRepository repository;
  late _MockDio dio;

  final user = UserEntity(
    id: 'user-1',
    username: 'lisa',
    fullName: 'Lisa Silva',
    nickname: 'Lisa',
    email: 'lisa@example.com',
    phone: '(85) 99999-1111',
    gender: 'FEMALE',
    birthDate: DateTime(1998, 4, 9),
  );

  Widget buildApp({
    String initialLocation = AppRoutes.homeMenuEditProfileInfo,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
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
          builder: (context, state) => const EditLoggedUserScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        dioClientProvider.overrideWithValue(dio),
      ],
      child: ToastificationWrapper(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    String initialLocation = AppRoutes.homeMenuEditProfileInfo,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp(initialLocation: initialLocation));
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    registerFallbackValue(_FakeUpdateLoggedUserRequestModel());
  });

  setUp(() {
    repository = _MockAuthRepository();
    dio = _MockDio();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);
    when(
      () => repository.updateLoggedUser(any()),
    ).thenAnswer((_) async => Right(user));
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
        data: {
          'id': 'user-1',
          'fullName': 'Lisa Silva',
          'nickname': 'Lisa',
          'gender': 'FEMALE',
          'birthDate': '1998-04-09',
          'phone': '(85) 99999-1111',
          'email': 'lisa@example.com',
          'addressId': 'address-1',
        },
      ),
    );
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/addresses/address-1'),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/addresses/address-1'),
        data: {
          'zip': '60000-000',
          'country': 'Brasil',
          'state': 'CE',
          'city': 'Fortaleza',
          'neighborhood': 'Centro',
          'street': 'Rua Alfa',
          'number': '123',
          'complement': 'Apto 4',
          'reference': 'Próximo à praça',
        },
      ),
    );
  });

  testWidgets('shows prefilled authenticated user data', (tester) async {
    await pumpApp(tester);

    expect(find.text('Editar dados pessoais'), findsOneWidget);
    expect(find.text('Lisa Silva'), findsOneWidget);
    expect(find.text('lisa@example.com'), findsOneWidget);
    expect(find.text('09/04/1998'), findsOneWidget);
  });

  testWidgets('does not show address section or address fields', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Endereço'), findsNothing);
    expect(find.text('CEP'), findsNothing);
    expect(find.text('País'), findsNothing);
    expect(find.text('Cidade'), findsNothing);
    expect(find.text('Rua'), findsNothing);
  });

  testWidgets('blocks submit when name is empty', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).first, '');
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    verifyNever(() => repository.updateLoggedUser(any()));
    expect(find.text('Campo obrigatório'), findsOneWidget);
  });

  testWidgets('blocks submit when birth date is invalid', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).at(2), '32132030');
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    verifyNever(() => repository.updateLoggedUser(any()));
    expect(find.text('Data inválida'), findsOneWidget);
  });

  testWidgets('blocks submit when birth date is future', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).at(2), '01013000');
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    verifyNever(() => repository.updateLoggedUser(any()));
    expect(find.text('Data não pode ser futura'), findsOneWidget);
  });

  testWidgets('blocks submit when gender is missing', (tester) async {
    when(() => repository.getCurrentUser()).thenAnswer(
      (_) async => UserEntity(
        id: 'user-1',
        username: 'lisa',
        fullName: 'Lisa Silva',
        email: 'lisa@example.com',
        birthDate: DateTime(1998, 4, 9),
      ),
    );
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
        data: {
          'id': 'user-1',
          'fullName': 'Lisa Silva',
          'birthDate': '1998-04-09',
          'email': 'lisa@example.com',
        },
      ),
    );

    await pumpApp(tester);

    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    verifyNever(() => repository.updateLoggedUser(any()));
    expect(find.text('Campo obrigatório'), findsOneWidget);
  });

  testWidgets('blocks submit when phone is incomplete', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).at(3), '8599');
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    verifyNever(() => repository.updateLoggedUser(any()));
    expect(find.text('Telefone inválido'), findsOneWidget);
  });

  testWidgets('blocks submit when email is invalid', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).at(4), 'email-invalido');
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    verifyNever(() => repository.updateLoggedUser(any()));
    expect(find.text('E-mail inválido'), findsOneWidget);
  });

  testWidgets('submits current form data and preserves current address', (
    tester,
  ) async {
    final completer = Completer<Either<Failure, UserEntity>>();
    when(
      () => repository.updateLoggedUser(any()),
    ).thenAnswer((_) => completer.future);

    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Lisa Souza');
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pump();

    final captured =
        verify(() => repository.updateLoggedUser(captureAny())).captured.single
            as UpdateLoggedUserRequestModel;
    expect(captured.fullName, 'Lisa Souza');
    expect(captured.address, isNotNull);
    expect(captured.address!.zip, '60000-000');
    expect(captured.address!.country, 'Brasil');
    expect(captured.address!.state, 'CE');
    expect(captured.address!.city, 'Fortaleza');
    expect(captured.address!.street, 'Rua Alfa');
    expect(captured.address!.number, '123');
  });

  testWidgets('shows loading state while saving', (tester) async {
    final completer = Completer<Either<Failure, UserEntity>>();
    when(
      () => repository.updateLoggedUser(any()),
    ).thenAnswer((_) => completer.future);

    await pumpApp(tester);

    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('invalidates profile and returns to summary after success', (
    tester,
  ) async {
    var profileLoads = 0;
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
    ).thenAnswer((_) async {
      profileLoads++;
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
        data: {
          'id': 'user-1',
          'fullName': profileLoads == 1 ? 'Lisa Silva' : 'Lisa Souza',
          'nickname': 'Lisa',
          'gender': 'FEMALE',
          'birthDate': '1998-04-09',
          'phone': '(85) 99999-1111',
          'email': 'lisa@example.com',
          'addressId': 'address-1',
        },
      );
    });

    await pumpApp(tester, initialLocation: AppRoutes.homeMenuEditProfile);

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Lisa Silva'), findsWidgets);

    await tester.tap(find.text('Editar dados pessoais'));
    await tester.pumpAndSettle();
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Lisa Souza'), findsWidgets);
    expect(profileLoads, 2);
  });

  testWidgets('returns to profile summary after direct edit success', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Editar dados pessoais'), findsOneWidget);

    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.byType(EditLoggedUserScreen), findsNothing);
  });
}

Finder _saveButton() => find.widgetWithText(ElevatedButton, 'Salvar');

Future<void> _scrollToSaveButton(WidgetTester tester) {
  return tester.dragUntilVisible(
    _saveButton(),
    find.byType(Scrollable).first,
    const Offset(0, -300),
  );
}
