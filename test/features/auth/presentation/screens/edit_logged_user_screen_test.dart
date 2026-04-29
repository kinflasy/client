import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/edit_logged_user_screen.dart';
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

  Widget buildApp() {
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
    when(() => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'))
        .thenAnswer(
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
        },
      ),
    );
  });

  testWidgets('shows prefilled authenticated user data', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Editar informações'), findsOneWidget);
    expect(find.text('Lisa Silva'), findsOneWidget);
    expect(find.text('lisa@example.com'), findsOneWidget);
    expect(find.text('09/04/1998'), findsOneWidget);
  });

  testWidgets('blocks submit when required fields are invalid', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.scrollUntilVisible(
      find.text('Salvar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.updateLoggedUser(any()));
  });

  testWidgets('shows loading state while saving', (tester) async {
    final completer = Completer<Either<Failure, UserEntity>>();
    when(
      () => repository.updateLoggedUser(any()),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Salvar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
