import 'dart:io';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/datasources/calendar_events_api.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/scale/data/models/scale_item_request_model.dart';
import 'package:client/features/calendar/data/repositories/calendar_event_repository_impl.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
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

    test('returns collaborators on success', () async {
      when(() => api.getCollaborators('event-1')).thenAnswer(
        (_) async => [
          {
            'id': 'collab-1',
            'calendarEventId': 'event-1',
            'department': {'id': 'dep-1', 'name': 'Louvor'},
          },
        ],
      );

      final result = await repository.getCollaborators('event-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (collaborators) {
        expect(collaborators.single.departmentId, 'dep-1');
        expect(collaborators.single.department?.name, 'Louvor');
      });
    });

    test('maps direct department collaborator response', () async {
      when(() => api.getCollaborators('event-1')).thenAnswer(
        (_) async => [
          {
            'id': 'dep-1',
            'unitId': 'unit-1',
            'name': 'Louvor',
            'slug': 'louvor',
            'type': 'ADMINISTRATIVE',
            'profileImageId': 'profile-1',
            'coverImageId': 'cover-1',
          },
        ],
      );

      final result = await repository.getCollaborators('event-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (collaborators) {
        expect(collaborators.single.departmentId, 'dep-1');
        expect(collaborators.single.department?.name, 'Louvor');
        expect(collaborators.single.department?.type, 'ADMINISTRATIVE');
      });
    });

    test('adds collaborator and maps response', () async {
      when(() => api.addCollaborator('event-1', 'dep-1')).thenAnswer(
        (_) async => {
          'id': 'collab-1',
          'calendarEventId': 'event-1',
          'departmentId': 'dep-1',
        },
      );

      final result = await repository.addCollaborator('event-1', 'dep-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (collaboration) {
        expect(collaboration.departmentId, 'dep-1');
      });
    });

    test('maps collaborator conflict into ValidationFailure', () async {
      when(
        () => api.addCollaborator('event-1', 'dep-1'),
      ).thenThrow(_dioError(409, 'Departamento ja colabora neste evento.'));

      final result = await repository.addCollaborator('event-1', 'dep-1');

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Departamento ja colabora neste evento.');
      }, (_) => fail('expected failure'));
    });

    test('removes collaborator', () async {
      when(
        () => api.removeCollaborator('event-1', 'dep-1'),
      ).thenAnswer((_) async {});

      final result = await repository.removeCollaborator('event-1', 'dep-1');

      expect(result.isRight(), isTrue);
      verify(() => api.removeCollaborator('event-1', 'dep-1')).called(1);
    });

    test('gets owner event scales and maps calendarEventId', () async {
      when(() => api.getEventScales('event-1')).thenAnswer(
        (_) async => const [
          {
            'id': 'scale-1',
            'lineupId': 'lineup-1',
            'type': 'OWNER',
            'calendarEventId': 'event-1',
          },
        ],
      );

      final result = await repository.getEventScales('event-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (scales) {
        expect(scales.single.id, 'scale-1');
        expect(scales.single.type, CalendarEventScaleType.owner);
        expect(scales.single.calendarEventId, 'event-1');
      });
    });

    test('gets collaborator event scales without breaking UI scope', () async {
      when(() => api.getEventScales('event-1')).thenAnswer(
        (_) async => const [
          {
            'id': 'scale-2',
            'lineupId': 'lineup-2',
            'type': 'COLLABORATOR',
            'collaborationId': 'collab-1',
          },
        ],
      );

      final result = await repository.getEventScales('event-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (scales) {
        expect(scales.single.type, CalendarEventScaleType.collaborator);
        expect(scales.single.collaborationId, 'collab-1');
      });
    });

    test('creates event scale and maps response', () async {
      when(
        () => api.createEventScale('event-1', any(that: isA<Map>())),
      ).thenAnswer(
        (_) async => const {
          'id': 'scale-1',
          'lineupId': 'lineup-1',
          'type': 'OWNER',
          'calendarEventId': 'event-1',
        },
      );

      final result = await repository.createEventScale(
        'event-1',
        const CalendarEventScaleRequestModel(lineupId: 'lineup-1'),
      );

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (scale) {
        expect(scale.lineupId, 'lineup-1');
        expect(scale.calendarEventId, 'event-1');
      });
      verify(
        () => api.createEventScale('event-1', {'lineupId': 'lineup-1'}),
      ).called(1);
    });

    test('maps scale creation conflict into ValidationFailure', () async {
      when(
        () => api.createEventScale('event-1', any(that: isA<Map>())),
      ).thenThrow(_dioError(409, 'Evento ja possui escala.'));

      final result = await repository.createEventScale(
        'event-1',
        const CalendarEventScaleRequestModel(lineupId: 'lineup-1'),
      );

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Evento ja possui escala.');
      }, (_) => fail('expected failure'));
    });

    test('gets scale by id and maps owner response', () async {
      when(() => api.getScaleById('scale-1')).thenAnswer(
        (_) async => const {
          'id': 'scale-1',
          'lineupId': 'lineup-1',
          'type': 'OWNER',
          'calendarEventId': 'event-1',
        },
      );

      final result = await repository.getScaleById('scale-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (scale) {
        expect(scale.id, 'scale-1');
        expect(scale.lineupId, 'lineup-1');
        expect(scale.type, CalendarEventScaleType.owner);
        expect(scale.calendarEventId, 'event-1');
      });
      verify(() => api.getScaleById('scale-1')).called(1);
    });

    test('maps scale by id DioException into Failure', () async {
      when(
        () => api.getScaleById('scale-1'),
      ).thenThrow(_dioError(500, 'Falha ao carregar escala.'));

      final result = await repository.getScaleById('scale-1');

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'Falha ao carregar escala.');
      }, (_) => fail('expected failure'));
    });

    test('gets scale items and preserves duplicated assignment rows', () async {
      when(() => api.getScaleItems('scale-1')).thenAnswer(
        (_) async => const [
          {
            'id': 'item-1',
            'scaleId': 'scale-1',
            'roleId': 'role-1',
            'personId': 'person-1',
          },
          {
            'id': 'item-2',
            'scaleId': 'scale-1',
            'roleId': 'role-1',
            'personId': 'person-1',
          },
        ],
      );

      final result = await repository.getScaleItems('scale-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (items) {
        expect(items, hasLength(2));
        expect(items.map((item) => item.id), ['item-1', 'item-2']);
        expect(items.map((item) => item.roleId), ['role-1', 'role-1']);
        expect(items.map((item) => item.personId), ['person-1', 'person-1']);
      });
      verify(() => api.getScaleItems('scale-1')).called(1);
    });

    test('maps scale items DioException into Failure', () async {
      when(
        () => api.getScaleItems('scale-1'),
      ).thenThrow(_dioError(500, 'Falha ao carregar alocacoes.'));

      final result = await repository.getScaleItems('scale-1');

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'Falha ao carregar alocacoes.');
      }, (_) => fail('expected failure'));
    });

    test('adds scale item and maps response', () async {
      when(() => api.addScaleItem('scale-1', any(that: isA<Map>()))).thenAnswer(
        (_) async => const {
          'id': 'item-1',
          'scaleId': 'scale-1',
          'roleId': 'role-1',
          'personId': 'person-1',
        },
      );

      final result = await repository.addScaleItem(
        scaleId: 'scale-1',
        request: const ScaleItemRequestModel(
          roleId: 'role-1',
          personId: 'person-1',
        ),
      );

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (item) {
        expect(item.id, 'item-1');
        expect(item.scaleId, 'scale-1');
        expect(item.roleId, 'role-1');
        expect(item.personId, 'person-1');
      });
      verify(
        () => api.addScaleItem('scale-1', {
          'roleId': 'role-1',
          'personId': 'person-1',
        }),
      ).called(1);
    });

    test('maps add scale item DioException into Failure', () async {
      when(
        () => api.addScaleItem('scale-1', any(that: isA<Map>())),
      ).thenThrow(_dioError(403, 'Sem permissao para editar escala.'));

      final result = await repository.addScaleItem(
        scaleId: 'scale-1',
        request: const ScaleItemRequestModel(
          roleId: 'role-1',
          personId: 'person-1',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Sem permissao para editar escala.');
      }, (_) => fail('expected failure'));
    });

    test('removes scale item and treats 204 as success', () async {
      when(
        () => api.removeScaleItem('scale-1', any(that: isA<Map>())),
      ).thenAnswer((_) async {});

      final result = await repository.removeScaleItem(
        scaleId: 'scale-1',
        request: const ScaleItemRequestModel(
          roleId: 'role-1',
          personId: 'person-1',
        ),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => api.removeScaleItem('scale-1', {
          'roleId': 'role-1',
          'personId': 'person-1',
        }),
      ).called(1);
    });

    test('maps remove scale item DioException into Failure', () async {
      when(
        () => api.removeScaleItem('scale-1', any(that: isA<Map>())),
      ).thenThrow(_dioError(500, 'Falha ao remover item.'));

      final result = await repository.removeScaleItem(
        scaleId: 'scale-1',
        request: const ScaleItemRequestModel(
          roleId: 'role-1',
          personId: 'person-1',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'Falha ao remover item.');
      }, (_) => fail('expected failure'));
    });

    test('gets department scales and maps embedded calendar event', () async {
      final start = DateTime(2026, 5, 30);
      final end = DateTime(2026, 11, 30, 23, 59, 59);
      when(() => api.getDepartmentScales('dep-1', start, end)).thenAnswer(
        (_) async => [
          {
            'id': 'scale-1',
            'lineupId': 'lineup-1',
            'type': 'OWNER',
            'calendarEventId': 'event-1',
            'calendarEvent': _eventJson(
              id: 'event-1',
              type: 'DEPARTMENT',
              ownerKey: 'departmentId',
              ownerId: 'dep-1',
            ),
          },
        ],
      );

      final result = await repository.getDepartmentScales('dep-1', start, end);

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (scales) {
        expect(scales.single.scale.id, 'scale-1');
        expect(scales.single.scale.calendarEventId, 'event-1');
        expect(scales.single.calendarEvent.id, 'event-1');
        expect(scales.single.calendarEvent.departmentId, 'dep-1');
      });
    });

    test('maps department scales DioException into Failure', () async {
      final start = DateTime(2026, 5, 30);
      final end = DateTime(2026, 11, 30, 23, 59, 59);
      when(
        () => api.getDepartmentScales('dep-1', start, end),
      ).thenThrow(_dioError(500, 'Falha ao listar escalas.'));

      final result = await repository.getDepartmentScales('dep-1', start, end);

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'Falha ao listar escalas.');
      }, (_) => fail('expected failure'));
    });

    test('maps department scale parse failure into UnknownFailure', () async {
      final start = DateTime(2026, 5, 30);
      final end = DateTime(2026, 11, 30, 23, 59, 59);
      when(() => api.getDepartmentScales('dep-1', start, end)).thenAnswer(
        (_) async => const [
          {'id': 'scale-1', 'lineupId': 'lineup-1', 'type': 'OWNER'},
        ],
      );

      final result = await repository.getDepartmentScales('dep-1', start, end);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('expected failure'),
      );
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
