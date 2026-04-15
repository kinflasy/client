import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/models/address_model.dart';
import 'package:client/features/membership/data/models/person_profile_model.dart';
import 'package:client/features/membership/data/models/update_inactive_person_request_model.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:fpdart/fpdart.dart';

abstract class MemberProfileRepository {
  Future<Either<Failure, PersonProfileModel>> getPersonProfile(String personId);

  Future<Either<Failure, AddressModel>> getAddress(String addressId);

  Future<Either<Failure, ActiveMembershipModel>> getActiveMembership({
    required String unitId,
    required String personId,
  });

  Future<Either<Failure, List<IntegrationEntity>>> getIntegrations(
    String membershipId,
  );

  Future<Either<Failure, void>> updateInactivePerson({
    required String personId,
    required UpdateInactivePersonRequestModel request,
  });
}
