import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/edit_logged_user_address_screen.dart';
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
    String initialLocation = AppRoutes.homeMenuEditProfileAddress,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.homeMenuEditProfile,
          name: AppRoutes.homeMenuEditProfileName,
          builder: (context, state) => const LoggedUserProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.homeMenuEditProfileAddress,
          name: AppRoutes.homeMenuEditProfileAddressName,
          builder: (context, state) => const EditLoggedUserAddressScreen(),
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
    String initialLocation = AppRoutes.homeMenuEditProfileAddress,
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
    _mockProfile(dio, fullName: 'Lisa Silva');
    _mockAddress(dio, city: 'Fortaleza', street: 'Rua Alfa', number: '123');
  });

  testWidgets('shows title and prefilled address fields', (tester) async {
    await pumpApp(tester);

    expect(find.text('Editar endereço'), findsOneWidget);
    expect(find.text('60000-000'), findsOneWidget);
    expect(find.text('Brasil'), findsOneWidget);
    expect(find.text('CE'), findsOneWidget);
    expect(find.text('Fortaleza'), findsOneWidget);
    expect(find.text('Rua Alfa'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('submits filled address and current personal data', (
    tester,
  ) async {
    final completer = Completer<Either<Failure, UserEntity>>();
    when(
      () => repository.updateLoggedUser(any()),
    ).thenAnswer((_) => completer.future);

    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '60100-000');
    await tester.enterText(find.byType(TextFormField).at(3), 'Sobral');
    await tester.enterText(find.byType(TextFormField).at(5), 'Rua Beta');
    await tester.enterText(find.byType(TextFormField).at(6), '456');
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pump();

    final captured =
        verify(() => repository.updateLoggedUser(captureAny())).captured.single
            as UpdateLoggedUserRequestModel;
    expect(captured.fullName, 'Lisa Silva');
    expect(captured.nickname, 'Lisa');
    expect(captured.gender, 'FEMALE');
    expect(captured.birthDate, '1998-04-09');
    expect(captured.phone, '85999991111');
    expect(captured.email, 'lisa@example.com');
    expect(captured.address, isNotNull);
    expect(captured.address!.zip, '60100-000');
    expect(captured.address!.country, 'Brasil');
    expect(captured.address!.state, 'CE');
    expect(captured.address!.city, 'Sobral');
    expect(captured.address!.street, 'Rua Beta');
    expect(captured.address!.number, '456');
  });

  testWidgets('submits non-null empty address when all fields are cleared', (
    tester,
  ) async {
    final completer = Completer<Either<Failure, UserEntity>>();
    when(
      () => repository.updateLoggedUser(any()),
    ).thenAnswer((_) => completer.future);

    await pumpApp(tester);

    for (var index = 0; index < 9; index++) {
      await tester.enterText(find.byType(TextFormField).at(index), '');
    }
    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pump();

    final captured =
        verify(() => repository.updateLoggedUser(captureAny())).captured.single
            as UpdateLoggedUserRequestModel;
    expect(captured.address, isNotNull);
    expect(captured.address!.zip, isNull);
    expect(captured.address!.country, isNull);
    expect(captured.address!.state, isNull);
    expect(captured.address!.city, isNull);
    expect(captured.address!.neighborhood, isNull);
    expect(captured.address!.street, isNull);
    expect(captured.address!.number, isNull);
    expect(captured.address!.complement, isNull);
    expect(captured.address!.reference, isNull);
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

  testWidgets('returns to profile summary after success', (tester) async {
    var profileLoads = 0;
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
    ).thenAnswer((_) async {
      profileLoads++;
      return Response<Map<String, dynamic>>(
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
      );
    });
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/addresses/address-1'),
    ).thenAnswer((_) async {
      final city = profileLoads == 1 ? 'Fortaleza' : 'Sobral';
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/addresses/address-1'),
        data: {
          'zip': '60000-000',
          'country': 'Brasil',
          'state': 'CE',
          'city': city,
          'street': 'Rua Alfa',
          'number': '123',
        },
      );
    });

    await pumpApp(tester);

    await _scrollToSaveButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.textContaining('Sobral'), findsOneWidget);
    expect(find.byType(EditLoggedUserAddressScreen), findsNothing);
    expect(profileLoads, 2);
  });
}

void _mockProfile(_MockDio dio, {required String fullName}) {
  when(
    () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
  ).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
      data: {
        'id': 'user-1',
        'fullName': fullName,
        'nickname': 'Lisa',
        'gender': 'FEMALE',
        'birthDate': '1998-04-09',
        'phone': '(85) 99999-1111',
        'email': 'lisa@example.com',
        'addressId': 'address-1',
      },
    ),
  );
}

void _mockAddress(
  _MockDio dio, {
  required String city,
  required String street,
  required String number,
}) {
  when(
    () => dio.get<Map<String, dynamic>>('/v1/core/addresses/address-1'),
  ).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/v1/core/addresses/address-1'),
      data: {
        'zip': '60000-000',
        'country': 'Brasil',
        'state': 'CE',
        'city': city,
        'neighborhood': 'Centro',
        'street': street,
        'number': number,
        'complement': 'Apto 4',
        'reference': 'Próximo à praça',
      },
    ),
  );
}

Finder _saveButton() => find.widgetWithText(ElevatedButton, 'Salvar');

Future<void> _scrollToSaveButton(WidgetTester tester) {
  return tester.dragUntilVisible(
    _saveButton(),
    find.byType(Scrollable).first,
    const Offset(0, -300),
  );
}
