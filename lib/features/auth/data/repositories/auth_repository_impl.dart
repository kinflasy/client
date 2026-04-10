import 'package:client/core/errors/failure.dart';
import 'package:client/core/storage/secure_storage.dart';
import 'package:client/features/auth/data/datasources/auth_api.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/data/models/user_model.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._storage);

  final AuthApi _api;
  final SecureStorage _storage;

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    var tokenSaved = false;

    try {
      final response = await _api.login(
        LoginRequestModel(username: email, password: password),
      );
      await _storage.saveToken(response.token);
      tokenSaved = true;

      final currentUser = await _resolveAuthenticatedUser();
      return Right(currentUser);
    } on DioException catch (e) {
      if (tokenSaved) {
        await _storage.deleteToken();
      }

      final statusCode = e.response?.statusCode;
      if (_isInvalidCredentialsStatus(statusCode)) {
        return Left(
          AuthFailure(
            tokenSaved
                ? 'Nao foi possivel validar a sessao do usuario'
                : 'Usuario ou senha incorretos',
          ),
        );
      }

      return Left(NetworkFailure('Erro de conexao'));
    } on _InvalidAuthenticatedUser catch (_) {
      if (tokenSaved) {
        await _storage.deleteToken();
      }
      return Left(
        const AuthFailure('Nao foi possivel carregar o usuario autenticado'),
      );
    } catch (_) {
      if (tokenSaved) {
        await _storage.deleteToken();
      }
      return Left(UnknownFailure('Erro inesperado'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final request = RegisterRequestModel(
        fullName: name,
        username: username,
        email: email,
        password: password,
        gender: 'MALE',
        birthDate: '2000-01-01',
      );

      final user = await _api.register(request);
      return Right(user.toEntity());
    } on DioException catch (e) {
      return Left(NetworkFailure('Erro de conexao: ${e.message}'));
    } catch (_) {
      return Left(UnknownFailure('Erro inesperado'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    await _storage.deleteToken();
    return const Right(null);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    try {
      if (JwtDecoder.isExpired(token)) {
        await _storage.deleteToken();
        return null;
      }
    } catch (_) {
      await _storage.deleteToken();
      return null;
    }

    try {
      return await _resolveAuthenticatedUser();
    } on DioException catch (_) {
      await _storage.deleteToken();
      return null;
    } on _InvalidAuthenticatedUser catch (_) {
      await _storage.deleteToken();
      return null;
    } catch (_) {
      await _storage.deleteToken();
      return null;
    }
  }

  Future<UserEntity> _resolveAuthenticatedUser() async {
    final user = (await _api.getLoggedUser()).toEntity();
    if (user.id.trim().isEmpty || user.username.trim().isEmpty) {
      throw const _InvalidAuthenticatedUser();
    }
    return user;
  }

  bool _isInvalidCredentialsStatus(int? statusCode) {
    return statusCode == 400 || statusCode == 401 || statusCode == 403;
  }
}

class _InvalidAuthenticatedUser implements Exception {
  const _InvalidAuthenticatedUser();
}
