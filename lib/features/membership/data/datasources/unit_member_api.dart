import 'package:client/features/membership/data/models/unit_member_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'unit_member_api.g.dart';

@RestApi()
abstract class UnitMemberApi {
  factory UnitMemberApi(Dio dio, {String baseUrl}) = _UnitMemberApi;

  @GET('/v1/core/church/units/{id}/members')
  Future<List<UnitMemberModel>> getUnitMembers(@Path('id') String unitId);

  @POST('/v1/core/church/units/{id}/members/register')
  Future<void> registerMember(
    @Path('id') String unitId,
    @Body() Map<String, dynamic> body,
  );

  @POST('/v1/core/churches/activate-member')
  Future<void> activateMember(@Body() Map<String, dynamic> body);
}
