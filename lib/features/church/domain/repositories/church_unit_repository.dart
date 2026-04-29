import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../entities/church_unit_entity.dart';

abstract class ChurchUnitRepository {
  Future<Either<Failure, ChurchUnitEntity>> getUnitById(String id);
  Future<Either<Failure, List<ChurchUnitEntity>>> getUnitsByChurchId(
    String churchId,
  );
  Future<Either<Failure, void>> joinUnit(String unitId, String affiliation);
  Future<Either<Failure, List<PendingUnitMembershipEntity>>> getPendingMembers(
    String unitId,
  );
  Future<Either<Failure, void>> confirmPendingMember(
    String unitId,
    String personId,
  );
  Future<Either<Failure, void>> rejectPendingMember(
    String unitId,
    String personId,
  );
}
