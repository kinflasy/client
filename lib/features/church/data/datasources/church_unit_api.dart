import 'package:dio/dio.dart';

class ChurchUnitApi {
  ChurchUnitApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getUnitById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/core/church/units/$id',
    );
    return response.data ?? <String, dynamic>{};
  }
}
