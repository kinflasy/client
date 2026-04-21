import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/models/church_read_models.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
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

  DepartmentEntity _mapModelToEntity(DepartmentReadModel model) {
    return DepartmentEntity(
      id: model.id,
      name: model.name,
      slug: model.slug,
      type: model.type,
    );
  }
}
