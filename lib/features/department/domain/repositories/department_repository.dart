import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/data/models/role_request_model.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
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

  Future<Either<Failure, Unit>> updateParticipantRole(
    String departmentId,
    IntegrationRequestModel request,
  );

  Future<Either<Failure, Unit>> removeParticipant(
    String departmentId,
    IntegrationRequestModel request,
  );

  Future<Either<Failure, List<RoleEntity>>> getRoles();

  Future<Either<Failure, RoleEntity>> createRole(RoleRequestModel request);

  Future<Either<Failure, List<LineupEntity>>> getDepartmentLineups(
    String departmentId,
  );

  Future<Either<Failure, LineupEntity>> createDepartmentLineup(
    String departmentId,
    LineupRequestModel request,
  );

  Future<Either<Failure, LineupEntity>> getLineupById(String lineupId);

  Future<Either<Failure, LineupEntity>> getLineupWithItems(String lineupId);

  Future<Either<Failure, LineupEntity>> updateLineup(
    String lineupId,
    LineupRequestModel request,
  );

  Future<Either<Failure, Unit>> deleteLineup(String lineupId);

  Future<Either<Failure, List<LineupItemEntity>>> getLineupItems(
    String lineupId,
  );

  Future<Either<Failure, LineupItemEntity>> createLineupItem(
    String lineupId,
    LineupItemRequestModel request,
  );

  Future<Either<Failure, LineupItemEntity>> updateLineupItem(
    String itemId,
    LineupItemUpdateRequestModel request,
  );

  Future<Either<Failure, Unit>> deleteLineupItem(String itemId);
}
