import 'dart:io';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/datasources/calendar_events_api.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/data/repositories/calendar_event_repository_impl.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarEventsApi extends Mock implements CalendarEventsApi {}

void main() {
  late _MockCalendarEventsApi api;
  late CalendarEventRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(MultipartFile.fromBytes([1], filename: 'card.png'));
  });

  setUp(() {
    api = _MockCalendarEventsApi();
    repository = CalendarEventRepositoryImpl(api);
  });

  group('CalendarEventRepositoryImpl', () {
    test('returns unit events on success', () async {
      final start = DateTime(2026, 5);
      final end = DateTime(2026, 6);
      when(() => api.getUnitEvents('unit-1', start, end)).thenAnswer(
        (_) async => [
          _eventJson(
            id: 'event-1',
            type: 'UNIT',
            ownerKey: 'unitId',
            ownerId: 'unit-1',
          ),
        ],
      );

      final result = await repository.getUnitEvents('unit-1', start, end);

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (events) {
        expect(events, hasLength(1));
        expect(events.single.id, 'event-1');
        expect(events.single.type, CalendarEventType.unit);
      });
    });

    test('maps DioException into NetworkFailure', () async {
      final start = DateTime(2026, 5);
      final end = DateTime(2026, 6);
      when(() => api.getDepartmentEvents('dep-1', start, end)).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/core/calendar-events/department/dep-1',
          ),
          message: 'offline',
        ),
      );

      final result = await repository.getDepartmentEvents('dep-1', start, end);

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'offline');
      }, (_) => fail('expected failure'));
    });

    test('maps 400 into ValidationFailure with backend message', () async {
      when(
        () => api.createUnitEvent('unit-1', any(that: isA<Map>())),
      ).thenThrow(_dioError(400, 'Data final deve ser posterior ao inicio.'));

      final result = await repository.createUnitEvent('unit-1', _request());

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Data final deve ser posterior ao inicio.');
      }, (_) => fail('expected failure'));
    });

    test('maps 403 into ValidationFailure', () async {
      when(
        () => api.deleteEvent('event-1'),
      ).thenThrow(_dioError(403, 'Voce nao pode remover este evento.'));

      final result = await repository.deleteEvent('event-1');

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Voce nao pode remover este evento.');
      }, (_) => fail('expected failure'));
    });

    test('maps 409 into ValidationFailure', () async {
      when(
        () => api.updateEvent('event-1', any(that: isA<Map>())),
      ).thenThrow(_dioError(409, 'Conflito de agenda.'));

      final result = await repository.updateEvent('event-1', _request());

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Conflito de agenda.');
      }, (_) => fail('expected failure'));
    });

    test('updates card image with multipart file and maps response', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'calendar-card-test',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final image = File('${tempDir.path}/card.png');
      await image.writeAsBytes([1, 2, 3]);

      when(
        () => api.updateCardImage('event-1', any(that: isA<MultipartFile>())),
      ).thenAnswer(
        (_) async => _eventJson(
          id: 'event-1',
          type: 'UNIT',
          ownerKey: 'unitId',
          ownerId: 'unit-1',
          cardImageId: 'media-1',
        ),
      );

      final result = await repository.updateCardImage('event-1', image.path);

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (event) {
        expect(event.cardImageId, 'media-1');
      });
      verify(
        () => api.updateCardImage('event-1', any(that: isA<MultipartFile>())),
      ).called(1);
    });

    test('fetches event detail when update response has no body', () async {
      when(
        () => api.updateEvent('event-1', any(that: isA<Map>())),
      ).thenAnswer((_) async => <String, dynamic>{});
      when(() => api.getEventById('event-1')).thenAnswer(
        (_) async => _eventJson(
          id: 'event-1',
          type: 'DEPARTMENT',
          ownerKey: 'departmentId',
          ownerId: 'dep-1',
        ),
      );

      final result = await repository.updateEvent('event-1', _request());

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (event) {
        expect(event.type, CalendarEventType.department);
        expect(event.departmentId, 'dep-1');
      });
      verify(() => api.getEventById('event-1')).called(1);
    });
  });
}

CalendarEventRequestModel _request() {
  return CalendarEventRequestModel(
    title: 'Evento',
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    visibilityRules: const [
      VisibilityRuleEntity.unit(
        unitId: 'unit-1',
        affiliation: Affiliation.visitor,
      ),
    ],
  );
}

Map<String, dynamic> _eventJson({
  required String id,
  required String type,
  required String ownerKey,
  required String ownerId,
  String? cardImageId,
}) {
  return {
    'id': id,
    'title': 'Evento',
    'description': 'Descricao do evento.',
    'startDateTime': '2026-05-10T18:00:00',
    'endDateTime': '2026-05-10T20:00:00',
    'type': type,
    ownerKey: ownerId,
    'cardImageId': cardImageId,
    'visibilityRules': [
      {'type': 'UNIT', 'unitId': 'unit-1', 'affiliation': 'VISITOR'},
    ],
  };
}

DioException _dioError(int statusCode, String message) {
  return DioException(
    requestOptions: RequestOptions(path: '/v1/core/calendar-events'),
    response: Response(
      requestOptions: RequestOptions(path: '/v1/core/calendar-events'),
      statusCode: statusCode,
      data: {'message': message},
    ),
  );
}
