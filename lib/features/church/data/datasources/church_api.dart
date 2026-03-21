import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/church_model.dart';
import '../models/church_request_model.dart';

part 'church_api.g.dart';

@RestApi()
abstract class ChurchApi {
  factory ChurchApi(Dio dio, {String baseUrl}) = _ChurchApi;

  @POST('/v1/core/churches')
  Future<ChurchStarterModel> createChurch(
    @Body() ChurchStarterRequestModel request,
  );
}