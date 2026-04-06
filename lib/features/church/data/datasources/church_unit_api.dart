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

  Future<List<Map<String, dynamic>>> getUnitsByChurchId(String churchId) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/churches/$churchId/units',
    );
    final data = response.data ?? <dynamic>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
