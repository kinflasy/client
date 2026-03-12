import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:client/features/membership/data/models/membership_model.dart';

part 'membership_api.g.dart';

@RestApi()
abstract class MembershipApi {
  factory MembershipApi(Dio dio) = _MembershipApi;

  @GET('/v1/core/church/units')
  Future<List<MembershipModel>> getMyMemberships();
}