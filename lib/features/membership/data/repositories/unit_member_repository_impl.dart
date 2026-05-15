import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/datasources/unit_member_api.dart';
import 'package:client/features/membership/data/models/register_member_request_model.dart';
import 'package:client/features/membership/data/models/unit_member_model.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/domain/repositories/unit_member_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class UnitMemberRepositoryImpl implements UnitMemberRepository {
  UnitMemberRepositoryImpl(this._api, this._dio);

  final UnitMemberApi _api;
  final Dio _dio;

  @override
  Future<Either<Failure, List<UnitMemberEntity>>> getUnitMembers(
    String unitId,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/v1/core/church/units/$unitId/members',
      );
      final data = response.data;
      if (data == null) {
        return const Left(ServerFailure('Resposta vazia ao carregar membros.'));
      }

      final models = <UnitMemberModel>[];
      for (final item in data) {
        if (item is! Map) {
          return const Left(
            ServerFailure('Resposta inesperada ao carregar membros.'),
          );
        }

        final json = Map<String, dynamic>.from(item);
        try {
          final normalized = _normalizeUnitMemberJson(json);
          models.add(UnitMemberModel.fromJson(normalized));
        } on FormatException catch (_) {
          return const Left(
            ServerFailure('Resposta inesperada ao carregar membros.'),
          );
        }
      }

      return Right(models.map((model) => model.toEntity()).toList());
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        return Left(
          NetworkFailure('Erro ao buscar membros (HTTP $statusCode).'),
        );
      }
      return const Left(NetworkFailure('Erro ao buscar membros.'));
    } on TypeError catch (_) {
      return const Left(
        ServerFailure('Resposta inesperada ao carregar membros.'),
      );
    } on FormatException catch (_) {
      return const Left(
        ServerFailure('Resposta inesperada ao carregar membros.'),
      );
    } catch (_) {
      return const Left(
        UnknownFailure('Não foi possível carregar os membros.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> registerMember(
    String unitId,
    RegisterMemberRequestModel request,
  ) async {
    try {
      await _api.registerMember(unitId, request.toJson());
      return const Right(null);
    } on DioException catch (_) {
      return const Left(NetworkFailure('Erro ao cadastrar membro'));
    } catch (_) {
      return const Left(UnknownFailure('Erro inesperado'));
    }
  }
}

Map<String, dynamic> _normalizeUnitMemberJson(Map<String, dynamic> json) {
  final personRaw = json['person'];
  if (personRaw is! Map) {
    throw const FormatException('Campo person ausente ou invalido');
  }

  final person = Map<String, dynamic>.from(personRaw);

  return {
    'id': _requiredString(json, ['id']),
    'unitId': _requiredString(json, ['unitId', 'unit_id']),
    'affiliation': _requiredString(json, ['affiliation']),
    'person': {
      'id': _requiredString(person, ['id']),
      'fullName': _requiredString(person, ['fullName', 'full_name']),
      'nickname': _optionalString(person, ['nickname']),
      'gender': _requiredString(person, ['gender']),
      'birthDate': _optionalString(person, ['birthDate', 'birth_date']),
      'phone': _optionalString(person, ['phone']),
      'addressId': _optionalString(person, ['addressId', 'address_id']),
      'profileImageId': _optionalString(person, [
        'profileImageId',
        'profile_image_id',
      ]),
    },
  };
}

String _requiredString(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value == null) {
    throw FormatException('Campo obrigatorio ausente: ${keys.join('/')}');
  }
  if (value is String) return value;
  return value.toString();
}

String? _optionalString(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}
