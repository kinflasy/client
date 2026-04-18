import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/models/department_request_model.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class ChurchDepartmentRepository {
  Future<Either<Failure, List<ChurchDepartmentEntity>>> getDepartmentsByUnitId(
    String unitId,
  );

  Future<Either<Failure, ChurchDepartmentEntity>> createDepartment(
    String unitId,
    DepartmentRequestModel request,
  );
}
