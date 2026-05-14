import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/data/models/user_model.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @POST('/auth/login')
  Future<LoginResponseModel> login(@Body() LoginRequestModel body);

  @POST('/auth/register')
  Future<UserModel> register(@Body() RegisterRequestModel body);

  @GET('/v1/core/users/identify')
  Future<UserModel> getLoggedUser();

  @PUT('/v1/core/users')
  Future<HttpResponse<Map<String, dynamic>?>> updateLoggedUser(
    @Body() UpdateLoggedUserRequestModel body,
  );

  @MultiPart()
  @PUT('/v1/core/people/profile-image')
  Future<UserModel> updateLoggedUserProfileImage(
    @Part(name: 'file') MultipartFile file,
  );

  @DELETE('/v1/core/people/profile-image')
  Future<void> deleteLoggedUserProfileImage();
}
