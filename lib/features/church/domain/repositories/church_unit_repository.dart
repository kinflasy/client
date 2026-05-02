import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/church_link_models.dart';
import '../../data/models/church_request_model.dart';
import '../entities/church_link_entity.dart';
import '../entities/church_unit_entity.dart';

abstract class ChurchUnitRepository {
  Future<Either<Failure, ChurchUnitEntity>> getUnitById(String id);
  Future<Either<Failure, List<ChurchUnitEntity>>> getUnitsByChurchId(
    String churchId,
  );
  Future<Either<Failure, ChurchUnitEntity>> updateUnit(
    String unitId,
    UnitRequestModel request,
  );
  Future<Either<Failure, void>> joinUnit(String unitId, String affiliation);
  Future<Either<Failure, List<PendingUnitMembershipEntity>>> getPendingMembers(
    String unitId,
  );
  Future<Either<Failure, void>> updatePendingMember(
    String unitId,
    String personId,
    String affiliation,
  );
  Future<Either<Failure, void>> confirmPendingMember(
    String unitId,
    String personId,
  );
  Future<Either<Failure, void>> rejectPendingMember(
    String unitId,
    String personId,
  );
  Future<Either<Failure, List<ChurchLinkEntity>>> getUnitLinks(String unitId);
  Future<Either<Failure, ChurchLinkEntity>> createUnitLink(
    String unitId,
    ChurchLinkRequestModel request,
  );
  Future<Either<Failure, ChurchLinkEntity>> updateLink(
    String linkId,
    ChurchLinkRequestModel request,
  );
  Future<Either<Failure, void>> deleteLink(String linkId);
}
