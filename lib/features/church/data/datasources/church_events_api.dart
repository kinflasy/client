import 'package:dio/dio.dart';

class ChurchEventsApi {
  ChurchEventsApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getEventsByUnitId({
    required String unitId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/calendar-events/unit/$unitId',
      queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    return response.data ?? <dynamic>[];
  }
}
