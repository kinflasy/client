import 'package:dio/dio.dart';

class DepartmentApi {
  DepartmentApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getDepartmentsByUnitId(String unitId) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/church/units/$unitId/departments',
    );
    return _readList(response.data);
  }

  Future<Map<String, dynamic>> createDepartment(
    String unitId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/core/church/units/$unitId/departments',
      data: payload,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getDepartmentById(String departmentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/core/church/unit/departments/$departmentId',
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<dynamic>> getParticipants(String departmentId) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/church/unit/departments/$departmentId/integrants',
    );
    return _readList(response.data);
  }

  Future<Map<String, dynamic>> addParticipant(
    String departmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/core/church/unit/departments/$departmentId/integrants',
      data: payload,
    );
    return response.data ?? <String, dynamic>{};
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

  List<dynamic> _readList(Object? data) {
    if (data is List) return data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['content', 'items', 'data', 'departments']) {
        final value = map[key];
        if (value is List) return value;
      }
    }

    return <dynamic>[];
  }
}
