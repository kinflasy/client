import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:client/features/membership/data/models/integration_model.dart';
import 'package:client/features/membership/data/models/membership_model.dart';

part 'membership_api.g.dart';

@RestApi()
abstract class MembershipApi {
  factory MembershipApi(Dio dio, {String baseUrl}) = _MembershipApi;

  @GET('/v1/core/church/units')
  Future<List<MembershipModel>> getMyMemberships();

  @GET('/v1/core/church/units/{unitId}/membership/{personId}')
  Future<ActiveMembershipModel> getMembershipByUnitAndPerson(
    @Path('unitId') String unitId,
    @Path('personId') String personId,
  );

  @GET('/v1/core/church/unit/memberships/{id}/integrations')
  Future<List<IntegrationModel>> getIntegrationsByMembershipId(
    @Path('id') String id,
  );
}
