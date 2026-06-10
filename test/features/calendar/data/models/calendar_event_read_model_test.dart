import 'package:client/features/calendar/data/models/calendar_event_read_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarEventReadModel.fromJson', () {
    test('parses unit event with visibility rules and card image', () {
      final model = CalendarEventReadModel.fromJson({
        'id': 'event-1',
        'title': 'Culto de Celebração',
        'description': 'Encontro aberto para a unidade.',
        'startDateTime': '2026-05-10T18:00:00',
        'endDateTime': '2026-05-10T20:00:00',
        'type': 'UNIT',
        'unitId': 'unit-1',
        'cardImageId': 'media-1',
        'visibilityRules': [
          {'type': 'UNIT', 'unitId': 'unit-1', 'affiliation': 'VISITOR'},
        ],
      });

      expect(model.id, 'event-1');
      expect(model.title, 'Culto de Celebração');
      expect(model.description, 'Encontro aberto para a unidade.');
      expect(model.startDateTime, DateTime(2026, 5, 10, 18));
      expect(model.endDateTime, DateTime(2026, 5, 10, 20));
      expect(model.type, CalendarEventType.unit);
      expect(model.unitId, 'unit-1');
      expect(model.departmentId, isNull);
      expect(model.cardImageId, 'media-1');
      expect(model.visibilityRules, hasLength(1));
      expect(model.visibilityRules.single.type, VisibilityRuleType.unit);

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.type, CalendarEventType.unit);
      expect(entity.visibilityRules, model.visibilityRules);
    });

    test('parses department event preserving department id', () {
      final model = CalendarEventReadModel.fromJson({
        'id': 'event-2',
        'title': 'Ensaio do Louvor',
        'startDateTime': '2026-05-12T19:00:00',
        'endDateTime': '2026-05-12T21:00:00',
        'type': 'DEPARTMENT',
        'departmentId': 'department-1',
        'visibilityRules': [
          {
            'type': 'DEPARTMENT',
            'departmentId': 'department-1',
            'integrationType': 'INTEGRANT',
          },
        ],
      });

      expect(model.id, 'event-2');
      expect(model.title, 'Ensaio do Louvor');
      expect(model.description, isNull);
      expect(model.type, CalendarEventType.department);
      expect(model.unitId, isNull);
      expect(model.departmentId, 'department-1');
      expect(model.cardImageId, isNull);
      expect(model.visibilityRules.single.type, VisibilityRuleType.department);

      final entity = model.toEntity();

      expect(entity.departmentId, 'department-1');
      expect(entity.type, CalendarEventType.department);
    });

    test('parses flexible ids, nested owner, and enveloped rules', () {
      final model = CalendarEventReadModel.fromJson({
        'id': 123,
        'title': 'Evento',
        'startDateTime': '2026-05-12T19:00:00',
        'endDateTime': '2026-05-12T21:00:00',
        'department': {'id': 456},
        'cardImage': {'id': 789},
        'visibilityRules': {
          'content': [
            {
              'type': 'DEPARTMENT',
              'departmentId': 456,
              'integrationType': 'INTEGRANT',
            },
          ],
        },
      });

      expect(model.id, '123');
      expect(model.type, CalendarEventType.department);
      expect(model.departmentId, '456');
      expect(model.cardImageId, '789');
      expect(model.visibilityRules, hasLength(1));
      expect(model.visibilityRules.single.departmentId, '456');
    });

    test('parses Java LocalDateTime arrays', () {
      final model = CalendarEventReadModel.fromJson({
        'id': 'event-3',
        'title': 'Evento',
        'startDateTime': [2026, 5, 12, 19, 30, 15, 123000000],
        'endDateTime': [2026, 5, 12, 21, 0],
        'unitId': 'unit-1',
      });

      expect(model.startDateTime, DateTime(2026, 5, 12, 19, 30, 15, 123));
      expect(model.endDateTime, DateTime(2026, 5, 12, 21));
    });

    test('parses date time objects', () {
      final model = CalendarEventReadModel.fromJson({
        'id': 'event-4',
        'title': 'Evento',
        'startDateTime': {
          'year': 2026,
          'monthValue': 5,
          'dayOfMonth': 12,
          'hour': 19,
          'minute': 30,
        },
        'endDateTime': {'year': 2026, 'month': 5, 'day': 12, 'hour': 21},
        'unitId': 'unit-1',
      });

      expect(model.startDateTime, DateTime(2026, 5, 12, 19, 30));
      expect(model.endDateTime, DateTime(2026, 5, 12, 21));
    });

    test('infers owner type when backend sends generic dto type', () {
      final departmentModel = CalendarEventReadModel.fromJson({
        'id': 'event-5',
        'title': 'Evento',
        'startDateTime': '2026-05-12T19:00:00',
        'endDateTime': '2026-05-12T21:00:00',
        'type': 'CalendarEventDto',
        'departmentId': 'department-1',
      });
      final unitModel = CalendarEventReadModel.fromJson({
        'id': 'event-6',
        'title': 'Evento',
        'startDateTime': '2026-05-12T19:00:00',
        'endDateTime': '2026-05-12T21:00:00',
        'type': 'CalendarEventDto',
        'unitId': 'unit-1',
      });

      expect(departmentModel.type, CalendarEventType.department);
      expect(unitModel.type, CalendarEventType.unit);
    });

    test('infers owner type when visible endpoint sends loose type', () {
      final departmentIdModel = CalendarEventReadModel.fromJson({
        'id': 'event-7',
        'title': 'Evento',
        'startDateTime': '2026-05-12T19:00:00',
        'endDateTime': '2026-05-12T21:00:00',
        'type': 'string',
        'departmentId': 'department-1',
        'visibilityRules': [
          {'type': 'string'},
          {
            'type': 'DEPARTMENT',
            'departmentId': 'department-1',
            'integrationType': 'OBSERVER',
          },
        ],
      });
      final nestedDepartmentModel = CalendarEventReadModel.fromJson({
        'id': 'event-8',
        'title': 'Evento',
        'startDateTime': '2026-05-12T19:00:00',
        'endDateTime': '2026-05-12T21:00:00',
        'type': 'string',
        'department': {'id': 'department-2', 'name': 'Louvor'},
      });
      final unitIdModel = CalendarEventReadModel.fromJson({
        'id': 'event-9',
        'title': 'Evento',
        'startDateTime': '2026-05-12T19:00:00',
        'endDateTime': '2026-05-12T21:00:00',
        'type': 'string',
        'unitId': 'unit-1',
      });
      final nestedUnitModel = CalendarEventReadModel.fromJson({
        'id': 'event-10',
        'title': 'Evento',
        'startDateTime': '2026-05-12T19:00:00',
        'endDateTime': '2026-05-12T21:00:00',
        'type': 'string',
        'unit': {'id': 'unit-2', 'name': 'Central'},
      });

      expect(departmentIdModel.type, CalendarEventType.department);
      expect(departmentIdModel.departmentId, 'department-1');
      expect(departmentIdModel.visibilityRules, hasLength(1));
      expect(nestedDepartmentModel.type, CalendarEventType.department);
      expect(nestedDepartmentModel.departmentId, 'department-2');
      expect(unitIdModel.type, CalendarEventType.unit);
      expect(unitIdModel.unitId, 'unit-1');
      expect(nestedUnitModel.type, CalendarEventType.unit);
      expect(nestedUnitModel.unitId, 'unit-2');
    });
  });
}
