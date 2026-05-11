import 'package:dio/dio.dart';

class CalendarEventsApi {
  CalendarEventsApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getUnitEvents(
    String unitId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/calendar-events/unit/$unitId',
      queryParameters: _rangeQuery(start, end),
    );
    return _readList(response.data);
  }

  Future<List<dynamic>> getDepartmentEvents(
    String departmentId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/calendar-events/department/$departmentId',
      queryParameters: _rangeQuery(start, end),
    );
    return _readList(response.data);
  }

  Future<Map<String, dynamic>> createUnitEvent(
    String unitId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/v1/core/calendar-events/unit/$unitId',
      data: payload,
    );
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> createDepartmentEvent(
    String departmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/v1/core/calendar-events/department/$departmentId',
      data: payload,
    );
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> getEventById(String eventId) async {
    final response = await _dio.get<dynamic>(
      '/v1/core/calendar-events/$eventId',
    );
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> updateEvent(
    String eventId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.put<dynamic>(
      '/v1/core/calendar-events/$eventId',
      data: payload,
    );
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> updateCardImage(
    String eventId,
    MultipartFile file,
  ) async {
    final response = await _dio.put<dynamic>(
      '/v1/core/calendar-events/$eventId/card-image',
      data: FormData.fromMap({'file': file}),
    );
    return _readMap(response.data);
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

  List<dynamic> _readList(Object? data) {
    if (data is List) return data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['content', 'items', 'data', 'events']) {
        final value = map[key];
        if (value is List) return value;
      }
    }

    return const [];
  }

  Map<String, dynamic> _readMap(Object? data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const [
        'event',
        'calendarEvent',
        'data',
        'content',
        'items',
        'events',
      ]) {
        final value = map[key];
        if (value is Map) return Map<String, dynamic>.from(value);
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
