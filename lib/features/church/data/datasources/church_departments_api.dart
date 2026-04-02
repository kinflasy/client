import 'package:dio/dio.dart';

class ChurchDepartmentsApi {
  ChurchDepartmentsApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getDepartmentsByUnitId(String unitId) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/church/units/$unitId/departments',
    );
    return response.data ?? <dynamic>[];
  }

  Future<Map<String, dynamic>> getDepartmentExtension(
    String departmentId,
    String extension,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/core/church/unit/departments/$departmentId/extensions/$extension',
    );
    return response.data ?? <String, dynamic>{};
  }
}
