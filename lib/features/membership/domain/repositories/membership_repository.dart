import 'package:fpdart/fpdart.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';

abstract class MembershipRepository {
  Future<Either<Failure, List<MembershipEntity>>> getMyMemberships();

  Future<Either<Failure, MembershipEntity>> getMembershipByUnitAndPerson(
    String unitId,
    String personId,
  );

  Future<Either<Failure, List<IntegrationEntity>>> getIntegrationsByMembershipId(
    String membershipId,
  );
}
