import 'dart:io';

import 'package:client/core/errors/failure.dart';
import 'package:client/core/storage/secure_storage.dart';
import 'package:client/features/auth/data/datasources/auth_api.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/data/models/user_model.dart';
import 'package:client/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _FakeLoginRequestModel extends Fake implements LoginRequestModel {}

class _FakeRegisterRequestModel extends Fake implements RegisterRequestModel {}

class _FakeUpdateLoggedUserRequestModel extends Fake
    implements UpdateLoggedUserRequestModel {}

void main() {
  late _MockAuthApi api;
  late _MockSecureStorage storage;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_FakeLoginRequestModel());
    registerFallbackValue(_FakeRegisterRequestModel());
    registerFallbackValue(_FakeUpdateLoggedUserRequestModel());
    registerFallbackValue(MultipartFile.fromBytes([0], filename: 'foto.png'));
  });

  setUp(() {
    api = _MockAuthApi();
    storage = _MockSecureStorage();
    repository = AuthRepositoryImpl(api, storage);
  });

  group('getCurrentUser', () {
    test('returns null and clears expired token before hitting api', () async {
      when(() => storage.getToken()).thenAnswer(
        (_) async =>
            'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MDAwMDAwMDB9.signature',
      );
      when(() => storage.deleteToken()).thenAnswer((_) async {});

      final user = await repository.getCurrentUser();

      expect(user, isNull);
      verify(() => storage.deleteToken()).called(1);
      verifyNever(() => api.getLoggedUser());
    });

    test('returns current user when token is still valid', () async {
      when(() => storage.getToken()).thenAnswer(
        (_) async =>
            'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjQ3MDAwMDAwMDB9.signature',
      );
      when(() => api.getLoggedUser()).thenAnswer(
        (_) async => const UserModel(
          id: 'user-1',
          username: 'lisa',
          email: 'lisa@example.com',
          fullName: 'Lisa Silva',
        ),
      );

      final user = await repository.getCurrentUser();

      expect(user, isNotNull);
      expect(user?.id, 'user-1');
      expect(user?.username, 'lisa');
      expect(user?.fullName, 'Lisa Silva');
      verify(() => api.getLoggedUser()).called(1);
      verifyNever(() => storage.deleteToken());
    });

    test('clears token when resolved user is missing identity fields', () async {
      when(() => storage.getToken()).thenAnswer(
        (_) async =>
            'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjQ3MDAwMDAwMDB9.signature',
      );
      when(() => api.getLoggedUser()).thenAnswer(
        (_) async => const UserModel(
          id: '',
          username: '   ',
          email: 'lisa@example.com',
          fullName: 'Lisa Silva',
        ),
      );
      when(() => storage.deleteToken()).thenAnswer((_) async {});

      final user = await repository.getCurrentUser();

      expect(user, isNull);
      verify(() => api.getLoggedUser()).called(1);
      verify(() => storage.deleteToken()).called(1);
    });
  });

  group('signIn', () {
    test(
      'returns auth failure when backend rejects credentials with 401',
      () async {
        when(() => api.login(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 401,
            ),
          ),
        );

        final result = await repository.signIn(
          email: 'lisa',
          password: 'wrong',
        );

        expect(result.isLeft(), isTrue);
        final failure = result.getLeft().toNullable();
        expect(failure, isA<AuthFailure>());
        expect(failure?.message, 'Usuário ou senha incorretos');
        verifyNever(() => storage.saveToken(any()));
        verifyNever(() => storage.deleteToken());
      },
    );

    test(
      'returns auth failure when backend rejects credentials with 403',
      () async {
        when(() => api.login(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 403,
            ),
          ),
        );

        final result = await repository.signIn(
          email: 'lisa',
          password: 'wrong',
        );

        expect(result.isLeft(), isTrue);
        final failure = result.getLeft().toNullable();
        expect(failure, isA<AuthFailure>());
        expect(failure?.message, 'Usuário ou senha incorretos');
        verifyNever(() => storage.saveToken(any()));
        verifyNever(() => storage.deleteToken());
      },
    );

    test('returns the logged user after saving the token', () async {
      when(
        () => api.login(any()),
      ).thenAnswer((_) async => const LoginResponseModel(token: 'jwt-token'));
      when(() => storage.saveToken('jwt-token')).thenAnswer((_) async {});
      when(() => api.getLoggedUser()).thenAnswer(
        (_) async => const UserModel(
          id: 'user-123',
          username: 'lisa',
          email: 'lisa@example.com',
          fullName: 'Lisa Silva',
        ),
      );

      final result = await repository.signIn(email: 'lisa', password: 'secret');

      expect(result.isRight(), isTrue);
      final user = result.getRight().toNullable();
      expect(user?.id, 'user-123');
      expect(user?.username, 'lisa');
      expect(user?.fullName, 'Lisa Silva');
      expect(user?.id, isNotEmpty);
      verify(() => storage.saveToken('jwt-token')).called(1);
      verify(() => api.getLoggedUser()).called(1);
      verifyNever(() => storage.deleteToken());
    });

    test(
      'returns auth failure and clears token when identity is incomplete',
      () async {
        when(
          () => api.login(any()),
        ).thenAnswer((_) async => const LoginResponseModel(token: 'jwt-token'));
        when(() => storage.saveToken('jwt-token')).thenAnswer((_) async {});
        when(() => storage.deleteToken()).thenAnswer((_) async {});
        when(() => api.getLoggedUser()).thenAnswer(
          (_) async => const UserModel(
            id: '',
            username: '',
            email: 'lisa@example.com',
            fullName: 'Lisa Silva',
          ),
        );

        final result = await repository.signIn(
          email: 'lisa',
          password: 'secret',
        );

        expect(result.isLeft(), isTrue);
        final failure = result.getLeft().toNullable();
        expect(failure, isA<AuthFailure>());
        expect(
          failure?.message,
          'Não foi possível carregar o usuário autenticado',
        );
        verify(() => storage.saveToken('jwt-token')).called(1);
        verify(() => api.getLoggedUser()).called(1);
        verify(() => storage.deleteToken()).called(1);
      },
    );

    test(
      'returns left and clears token when getLoggedUser fails after saving token',
      () async {
        when(
          () => api.login(any()),
        ).thenAnswer((_) async => const LoginResponseModel(token: 'jwt-token'));
        when(() => storage.saveToken('jwt-token')).thenAnswer((_) async {});
        when(() => storage.deleteToken()).thenAnswer((_) async {});
        when(() => api.getLoggedUser()).thenThrow(
          DioException(requestOptions: RequestOptions(path: '/identify')),
        );

        final result = await repository.signIn(
          email: 'lisa',
          password: 'secret',
        );

        expect(result.isLeft(), isTrue);
        expect(result.getLeft().toNullable(), isA<NetworkFailure>());
        verify(() => storage.saveToken('jwt-token')).called(1);
        verify(() => api.getLoggedUser()).called(1);
        verify(() => storage.deleteToken()).called(1);
      },
    );
  });

  group('signUp', () {
    test('sends gender and formatted birthDate received from caller', () async {
      when(() => api.register(any())).thenAnswer(
        (_) async => const UserModel(
          id: 'user-456',
          username: 'lisa',
          email: 'lisa@example.com',
          fullName: 'Lisa Silva',
          gender: 'FEMALE',
          birthDate: '1998-04-09',
        ),
      );

      final result = await repository.signUp(
        name: 'Lisa Silva',
        username: 'lisa',
        email: 'lisa@example.com',
        password: 'secret',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
      );

      expect(result.isRight(), isTrue);

      final captured =
          verify(() => api.register(captureAny())).captured.single
              as RegisterRequestModel;
      expect(captured.fullName, 'Lisa Silva');
      expect(captured.username, 'lisa');
      expect(captured.email, 'lisa@example.com');
      expect(captured.password, 'secret');
      expect(captured.gender, 'FEMALE');
      expect(captured.birthDate, '1998-04-09');
    });
  });

  group('updateLoggedUser', () {
    test('returns updated user when api succeeds', () async {
      when(() => api.updateLoggedUser(any())).thenAnswer(
        (_) async => const UserModel(
          id: 'user-123',
          username: 'lisa',
          email: 'novo@example.com',
          fullName: 'Lisa Atualizada',
          nickname: 'Lili',
        ),
      );

      final result = await repository.updateLoggedUser(
        const UpdateLoggedUserRequestModel(
          fullName: 'Lisa Atualizada',
          nickname: 'Lili',
          gender: 'FEMALE',
          birthDate: '1998-04-09',
          phone: '85999991111',
          email: 'novo@example.com',
        ),
      );

      expect(result.isRight(), isTrue);
      final user = result.getRight().toNullable();
      expect(user?.fullName, 'Lisa Atualizada');
      expect(user?.email, 'novo@example.com');
    });

    test('returns validation failure for 422 with backend message', () async {
      when(() => api.updateLoggedUser(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/core/users'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/core/users'),
            statusCode: 422,
            data: {'message': 'E-mail já está em uso'},
          ),
        ),
      );

      final result = await repository.updateLoggedUser(
        const UpdateLoggedUserRequestModel(
          fullName: 'Lisa Atualizada',
          gender: 'FEMALE',
          birthDate: '1998-04-09',
        ),
      );

      expect(result.isLeft(), isTrue);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect(failure?.message, 'E-mail já está em uso');
    });
  });

  group('profile image', () {
    test('uploads image file and returns updated user', () async {
      final directory = await Directory.systemTemp.createTemp('auth-image-');
      addTearDown(() => directory.delete(recursive: true));
      final image = File('${directory.path}/perfil.png');
      await image.writeAsBytes([1, 2, 3]);

      when(() => api.updateLoggedUserProfileImage(any())).thenAnswer(
        (_) async => const UserModel(
          id: 'user-123',
          username: 'lisa',
          profileImageId: 'image-123',
        ),
      );

      final result = await repository.updateLoggedUserProfileImage(image.path);

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()?.profileImageId, 'image-123');
      final captured =
          verify(
                () => api.updateLoggedUserProfileImage(captureAny()),
              ).captured.single
              as MultipartFile;
      expect(captured.filename, 'perfil.png');
    });

    test('deletes logged user profile image', () async {
      when(() => api.deleteLoggedUserProfileImage()).thenAnswer((_) async {});

      final result = await repository.deleteLoggedUserProfileImage();

      expect(result.isRight(), isTrue);
      verify(() => api.deleteLoggedUserProfileImage()).called(1);
    });

    test('returns friendly message for upload error 413', () async {
      final directory = await Directory.systemTemp.createTemp('auth-image-');
      addTearDown(() => directory.delete(recursive: true));
      final image = File('${directory.path}/grande.png');
      await image.writeAsBytes([1, 2, 3]);

      when(() => api.updateLoggedUserProfileImage(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/core/people/profile-image'),
          response: Response(
            requestOptions: RequestOptions(
              path: '/v1/core/people/profile-image',
            ),
            statusCode: 413,
          ),
        ),
      );

      final result = await repository.updateLoggedUserProfileImage(image.path);

      expect(result.isLeft(), isTrue);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<NetworkFailure>());
      expect(
        failure?.message,
        'Arquivo muito grande. Envie uma imagem de até 2 MB.',
      );
    });
  });
}
