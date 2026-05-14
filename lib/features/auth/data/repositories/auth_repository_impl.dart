import 'package:client/core/errors/failure.dart';
import 'package:client/core/storage/secure_storage.dart';
import 'package:client/core/utils/backend_date_parser.dart';
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

      return Left(NetworkFailure('Erro de conexão'));
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
      final response = await _api.updateLoggedUser(request);
      final authenticatedUser = await _resolveAuthenticatedUser();
      final user =
          _mergeCanonicalLoggedUser(authenticatedUser, response.data) ??
          _mergeUpdatedLoggedUser(authenticatedUser, request);
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

  @override
  Future<Either<Failure, UserEntity>> updateLoggedUserProfileImage(
    String filePath,
  ) async {
    try {
      final file = await MultipartFile.fromFile(filePath);
      final user = (await _api.updateLoggedUserProfileImage(file)).toEntity();
      if (user.id.trim().isEmpty || user.username.trim().isEmpty) {
        return const Left(
          AuthFailure('Não foi possível carregar o usuário autenticado'),
        );
      }
      return Right(user);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(
          _extractUploadErrorMessage(e, 'Erro ao atualizar a foto de perfil.'),
        ),
      );
    } catch (_) {
      return const Left(UnknownFailure('Erro inesperado'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLoggedUserProfileImage() async {
    try {
      await _api.deleteLoggedUserProfileImage();
      return const Right(null);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e.response?.data);
      return Left(
        NetworkFailure(message ?? 'Erro ao remover a foto de perfil.'),
      );
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
      if (errors is Map) {
        for (final value in errors.values) {
          final message = _extractErrorMessage(value);
          if (message != null) return message;
        }
      }
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

    if (data is Map) {
      for (final value in data.values) {
        final message = _extractErrorMessage(value);
        if (message != null) return message;
      }
    }

    if (data is List) {
      for (final value in data) {
        final message = _extractErrorMessage(value);
        if (message != null) return message;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }

  String _extractUploadErrorMessage(
    DioException error,
    String fallbackMessage,
  ) {
    if (error.response?.statusCode == 413) {
      return _extractErrorMessage(error.response?.data) ??
          'Arquivo muito grande. Envie uma imagem de até 2 MB.';
    }

    return _extractErrorMessage(error.response?.data) ??
        error.message ??
        fallbackMessage;
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  UserEntity _mergeUpdatedLoggedUser(
    UserEntity user,
    UpdateLoggedUserRequestModel request,
  ) {
    return UserEntity(
      id: user.id,
      username: user.username,
      email: request.email ?? user.email,
      fullName: request.fullName,
      nickname: request.nickname,
      phone: request.phone,
      gender: request.gender,
      birthDate: DateTime.tryParse(request.birthDate) ?? user.birthDate,
      profileImageId: user.profileImageId,
    );
  }

  UserEntity? _mergeCanonicalLoggedUser(
    UserEntity user,
    Map<String, dynamic>? data,
  ) {
    if (data == null || data.isEmpty) return null;

    final id = _readString(data, 'id') ?? user.id;
    final username = _readString(data, 'username') ?? user.username;
    if (id.trim().isEmpty || username.trim().isEmpty) return null;

    return UserEntity(
      id: id,
      username: username,
      email: _readString(data, 'email') ?? user.email,
      fullName:
          _readString(data, 'fullName') ??
          _readString(data, 'full_name') ??
          user.fullName,
      nickname: _readString(data, 'nickname') ?? user.nickname,
      phone: _readString(data, 'phone') ?? user.phone,
      gender: _readString(data, 'gender') ?? user.gender,
      birthDate:
          parseBackendDate(
            data.containsKey('birthDate')
                ? data['birthDate']
                : data['birth_date'],
          ) ??
          user.birthDate,
      profileImageId:
          _readString(data, 'profileImageId') ??
          _readString(data, 'profile_image_id') ??
          user.profileImageId,
    );
  }

  String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class _InvalidAuthenticatedUser implements Exception {
  const _InvalidAuthenticatedUser();
}
