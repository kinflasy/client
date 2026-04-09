import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/models/register_member_request_model.dart';
import 'package:fpdart/fpdart.dart';

abstract class UnitMemberRepository {
  Future<Either<Failure, void>> registerMember(
    String unitId,
    RegisterMemberRequestModel request,
  );
}
