import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'unit_member_api.g.dart';

@RestApi()
abstract class UnitMemberApi {
  factory UnitMemberApi(Dio dio, {String baseUrl}) = _UnitMemberApi;

  @POST('/v1/core/church/units/{id}/members/register')
  Future<void> registerMember(
    @Path('id') String unitId,
    @Body() Map<String, dynamic> body,
  );
}
