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
}
