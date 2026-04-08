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
    try {
      final response = await _api.login(
        LoginRequestModel(username: email, password: password),
      );
      await _storage.saveToken(response.token);
      final currentUser = await _api.getLoggedUser();
      return Right(currentUser.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure('Usuário ou senha inválidos'));
      }
      return Left(NetworkFailure('Erro de conexão'));
    } catch (_) {
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
      return Left(NetworkFailure('Erro de conexão: ${e.message}'));
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
      final userModel = await _api.getLoggedUser();
      return userModel.toEntity();
    } on DioException catch (_) {
      await _storage.deleteToken();
      return null;
    } catch (_) {
      await _storage.deleteToken();
      return null;
    }
  }
}
