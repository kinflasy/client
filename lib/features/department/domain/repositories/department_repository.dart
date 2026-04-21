import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class DepartmentRepository {
  Future<Either<Failure, List<DepartmentEntity>>> getDepartmentsByUnitId(
    String unitId,
  );

  Future<Either<Failure, DepartmentEntity>> createDepartment(
    String unitId,
    DepartmentRequestModel request,
  );
}
