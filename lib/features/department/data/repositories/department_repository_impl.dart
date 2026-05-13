import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/models/church_read_models.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class DepartmentRepositoryImpl implements DepartmentRepository {
  DepartmentRepositoryImpl(this._api);

  final DepartmentApi _api;

  @override
  Future<Either<Failure, List<DepartmentEntity>>> getDepartmentsByUnitId(
    String unitId,
  ) async {
    try {
      final jsonList = await _api.getDepartmentsByUnitId(unitId);
      final departments = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(DepartmentReadModel.fromJson)
          .where((model) => model.id.isNotEmpty)
          .map(_mapModelToEntity)
          .toList();
      return Right(departments);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(e.message ?? 'Erro ao carregar departamentos.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DepartmentEntity>> createDepartment(
    String unitId,
    DepartmentRequestModel request,
  ) async {
    try {
      final json = await _api.createDepartment(unitId, request.toJson());
      final model = DepartmentReadModel.fromJson(json);
      return Right(_mapModelToEntity(model));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 409) {
        final message =
            e.response?.data?['message'] as String? ??
            'Dados invalidos. Verifique as informacoes e tente novamente.';
        return Left(ValidationFailure(message));
      }
      return Left(NetworkFailure(e.message ?? 'Erro ao criar departamento.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DepartmentDetailEntity>> getDepartmentById(
    String departmentId,
  ) async {
    try {
      final json = await _api.getDepartmentById(departmentId);
      final department = _mapDetailJsonToEntity(json);
      return Right(department);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(e.message ?? 'Erro ao carregar departamento.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DepartmentParticipantEntity>>> getParticipants(
    String departmentId,
  ) async {
    try {
      final jsonList = await _api.getParticipants(departmentId);
      final participants = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_mapParticipantJsonToEntity)
          .where((participant) => participant.personId.isNotEmpty)
          .toList();

      return Right(participants);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(e.message ?? 'Erro ao carregar participantes.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addParticipant(
    String departmentId,
    IntegrationRequestModel request,
  ) async {
    try {
      await _api.addParticipant(departmentId, request.toJson());
      return const Right(unit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 403 || statusCode == 409) {
        final message =
            _readMap(e.response?.data)['message'] as String? ??
            'Não foi possível adicionar este participante.';
        return Left(ValidationFailure(message));
      }
      return Left(
        NetworkFailure(e.message ?? 'Erro ao adicionar participante.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  DepartmentEntity _mapModelToEntity(DepartmentReadModel model) {
    return DepartmentEntity(
      id: model.id,
      name: model.name,
      slug: model.slug,
      type: model.type,
    );
  }

  DepartmentDetailEntity _mapDetailJsonToEntity(Map<String, dynamic> json) {
    return DepartmentDetailEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      type: json['type'] as String?,
    );
  }

  DepartmentParticipantEntity _mapParticipantJsonToEntity(
    Map<String, dynamic> json,
  ) {
    final membership = _readMap(json['membership']);
    final person = _readMap(membership['person']);

    return DepartmentParticipantEntity(
      personId: person['id'] as String? ?? '',
      nickname: person['nickname'] as String?,
      username: person['username'] as String?,
      affiliation: membership['affiliation'] as String? ?? '',
      gender: person['gender'] as String? ?? '',
      birthDate: _parseDate(person['birthDate']),
      age: _parseInt(person['age']),
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Map<String, dynamic> _readMap(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
