import 'package:dio/dio.dart';

class CalendarEventsApi {
  CalendarEventsApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getUnitEvents(
    String unitId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/calendar-events/unit/$unitId',
      queryParameters: _rangeQuery(start, end),
    );
    return response.data ?? <dynamic>[];
  }

  Future<List<dynamic>> getDepartmentEvents(
    String departmentId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/calendar-events/department/$departmentId',
      queryParameters: _rangeQuery(start, end),
    );
    return response.data ?? <dynamic>[];
  }

  Future<Map<String, dynamic>> createUnitEvent(
    String unitId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/core/calendar-events/unit/$unitId',
      data: payload,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createDepartmentEvent(
    String departmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/core/calendar-events/department/$departmentId',
      data: payload,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getEventById(String eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/core/calendar-events/$eventId',
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateEvent(
    String eventId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/core/calendar-events/$eventId',
      data: payload,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateCardImage(
    String eventId,
    MultipartFile file,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/core/calendar-events/$eventId/card-image',
      data: FormData.fromMap({'file': file}),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> deleteCardImage(String eventId) async {
    await _dio.delete<void>('/v1/core/calendar-events/$eventId/card-image');
  }

  Future<void> deleteEvent(String eventId) async {
    await _dio.delete<void>('/v1/core/calendar-events/$eventId/delete');
  }

  Map<String, dynamic> _rangeQuery(DateTime start, DateTime end) {
    return {'start': start.toIso8601String(), 'end': end.toIso8601String()};
  }
}
