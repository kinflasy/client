import 'package:client/core/storage/secure_storage.dart';
import 'package:client/features/auth/data/datasources/auth_api.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/data/models/user_model.dart';
import 'package:client/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _FakeLoginRequestModel extends Fake implements LoginRequestModel {}

void main() {
  late _MockAuthApi api;
  late _MockSecureStorage storage;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_FakeLoginRequestModel());
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
          fullName: 'Lisa',
        ),
      );

      final user = await repository.getCurrentUser();

      expect(user, isNotNull);
      expect(user?.id, 'user-1');
      verify(() => api.getLoggedUser()).called(1);
      verifyNever(() => storage.deleteToken());
    });
  });

  group('signIn', () {
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
          fullName: 'Lisa',
        ),
      );

      final result = await repository.signIn(email: 'lisa', password: 'secret');

      expect(result.isRight(), isTrue);
      final user = result.getRight().toNullable();
      expect(user?.id, 'user-123');
      verify(() => storage.saveToken('jwt-token')).called(1);
      verify(() => api.getLoggedUser()).called(1);
    });
  });
}
