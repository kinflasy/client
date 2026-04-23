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
                ? 'Não foi possível validar a sessão do usuário'
                : 'Usuário ou senha incorretos',
          ),
        );
      }

      return Left(NetworkFailure('Erro de conexao'));
    } on _InvalidAuthenticatedUser catch (_) {
      if (tokenSaved) {
        await _storage.deleteToken();
      }
      return Left(
        const AuthFailure('Não foi possível carregar o usuário autenticado'),
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
    required String gender,
    required DateTime birthDate,
  }) async {
    try {
      final request = RegisterRequestModel(
        fullName: name,
        username: username,
        email: email,
        password: password,
        gender: gender,
        birthDate: _formatApiDate(birthDate),
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

  @override
  Future<Either<Failure, UserEntity>> updateLoggedUser(
    UpdateLoggedUserRequestModel request,
  ) async {
    try {
      final user = (await _api.updateLoggedUser(request)).toEntity();
      if (user.id.trim().isEmpty || user.username.trim().isEmpty) {
        return const Left(
          AuthFailure('Não foi possível carregar o usuário autenticado'),
        );
      }
      return Right(user);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      final message = _extractErrorMessage(data);

      if (statusCode == 400 || statusCode == 422) {
        return Left(
          ValidationFailure(
            message ?? 'Não foi possível validar os dados informados.',
          ),
        );
      }

      return Left(NetworkFailure(message ?? 'Erro de conexão'));
    } catch (_) {
      return const Left(UnknownFailure('Erro inesperado'));
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

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final directMessage = data['message'];
      if (directMessage is String && directMessage.trim().isNotEmpty) {
        return directMessage.trim();
      }

      final errors = data['errors'];
      if (errors is List) {
        for (final error in errors) {
          if (error is Map<String, dynamic>) {
            final message = error['message'];
            if (message is String && message.trim().isNotEmpty) {
              return message.trim();
            }
          } else if (error is String && error.trim().isNotEmpty) {
            return error.trim();
          }
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _InvalidAuthenticatedUser implements Exception {
  const _InvalidAuthenticatedUser();
}
