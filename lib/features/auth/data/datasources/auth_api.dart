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

  @GET('/v1/core/users/@{username}')
  Future<UserModel> getUserByUsername(@Path('username') String username);
}