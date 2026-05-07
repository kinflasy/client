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
  });
}
