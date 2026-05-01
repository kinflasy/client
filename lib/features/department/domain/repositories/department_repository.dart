import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class DepartmentRepository {
  Future<Either<Failure, List<DepartmentEntity>>> getDepartmentsByUnitId(
    String unitId,
  );

  Future<Either<Failure, DepartmentEntity>> createDepartment(
    String unitId,
    DepartmentRequestModel request,
  );

  Future<Either<Failure, DepartmentDetailEntity>> getDepartmentById(
    String departmentId,
  );

  Future<Either<Failure, List<DepartmentParticipantEntity>>> getParticipants(
    String departmentId,
  );

  Future<Either<Failure, Unit>> addParticipant(
    String departmentId,
    IntegrationRequestModel request,
  );
}
