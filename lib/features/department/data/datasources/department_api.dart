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

  Future<Map<String, dynamic>> updateParticipantRole(
    String departmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/core/church/unit/departments/$departmentId/integrants',
      data: payload,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> removeParticipant(
    String departmentId,
    Map<String, dynamic> payload,
  ) async {
    await _dio.delete<void>(
      '/v1/core/church/unit/departments/$departmentId/integrants',
      data: payload,
    );
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

  Future<List<dynamic>> getRoles() async {
    final response = await _dio.get<dynamic>('/v1/core/roles');
    return _readList(response.data);
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> payload) async {
    final response = await _dio.post<dynamic>('/v1/core/roles', data: payload);
    return _readMap(response.data);
  }

  Future<List<dynamic>> getDepartmentLineups(String departmentId) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/church/unit/departments/$departmentId/lineups',
    );
    return _readList(response.data);
  }

  Future<Map<String, dynamic>> createDepartmentLineup(
    String departmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/v1/core/church/unit/departments/$departmentId/lineups',
      data: payload,
    );
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> getLineupById(String lineupId) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/church/unit/lineups/$lineupId',
    );
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> getLineupWithItems(String lineupId) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/church/unit/lineups/$lineupId/with-items',
    );
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> updateLineup(
    String lineupId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.put<dynamic>(
      '/v1/core/church/unit/lineups/$lineupId',
      data: payload,
    );
    return _readMap(response.data);
  }

  Future<void> deleteLineup(String lineupId) async {
    await _dio.delete<void>('/v1/core/church/unit/lineups/$lineupId');
  }

  Future<List<dynamic>> getLineupItems(String lineupId) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/church/unit/lineups/$lineupId/items',
    );
    return _readList(response.data);
  }

  Future<Map<String, dynamic>> createLineupItem(
    String lineupId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/v1/core/church/unit/lineups/$lineupId/items',
      data: payload,
    );
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> updateLineupItem(
    String itemId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.put<dynamic>(
      '/v1/core/church/unit/lineups/items/$itemId',
      data: payload,
    );
    return _readMap(response.data);
  }

  Future<void> deleteLineupItem(String itemId) async {
    await _dio.delete<void>('/v1/core/church/unit/lineups/items/$itemId');
  }

  List<dynamic> _readList(Object? data) {
    if (data is List) return data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const [
        'content',
        'items',
        'data',
        'departments',
        'roles',
        'lineups',
      ]) {
        final value = map[key];
        if (value is List) return value;
      }
    }

    return <dynamic>[];
  }

  Map<String, dynamic> _readMap(Object? data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map.containsKey('id')) return map;

      for (final key in const [
        'role',
        'lineup',
        'departmentLineup',
        'unitLineup',
        'item',
        'lineupItem',
        'data',
        'content',
        'items',
        'roles',
        'lineups',
      ]) {
        final value = map[key];
        if (value is Map) return _readMap(value);
        if (value is List) return _readMap(value);
      }
      return map;
    }

    if (data is List) {
      for (final item in data) {
        if (item is Map) return Map<String, dynamic>.from(item);
      }
    }

    return <String, dynamic>{};
  }
}
