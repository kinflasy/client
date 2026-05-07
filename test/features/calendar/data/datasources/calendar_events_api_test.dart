import 'package:client/features/calendar/data/datasources/calendar_events_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late CalendarEventsApi api;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    dio = _MockDio();
    api = CalendarEventsApi(dio);
  });

  test('sends card image upload as multipart file field', () async {
    when(
      () => dio.put<Map<String, dynamic>>(
        '/v1/core/calendar-events/event-1/card-image',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/event-1/card-image',
        ),
        data: {'id': 'event-1'},
      ),
    );

    final file = MultipartFile.fromBytes([1, 2, 3], filename: 'card.png');

    await api.updateCardImage('event-1', file);

    final data =
        verify(
              () => dio.put<Map<String, dynamic>>(
                '/v1/core/calendar-events/event-1/card-image',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as FormData;

    expect(data.files, hasLength(1));
    expect(data.files.single.key, 'file');
    expect(data.files.single.value.filename, 'card.png');
  });
}
