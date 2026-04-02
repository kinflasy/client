import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/church_read_models.dart';
import '../models/church_model.dart';

part 'church_api.g.dart';

@RestApi()
abstract class ChurchApi {
  factory ChurchApi(Dio dio, {String baseUrl}) = _ChurchApi;

  @POST('/v1/core/churches')
  Future<ChurchStarterModel> createChurch(
    @Body() Map<String, dynamic> request,
  );

  @GET('/v1/core/churches/{id}')
  Future<ChurchReadModel> getChurchById(@Path('id') String id);
}
