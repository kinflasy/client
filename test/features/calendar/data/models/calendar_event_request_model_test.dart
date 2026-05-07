import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarEventRequestModel.toJson', () {
    test('serializes unit, department, user and church rules in uppercase', () {
      final model = CalendarEventRequestModel(
        title: 'Retiro de Jovens',
        description: 'Programação de fim de semana.',
        startDateTime: DateTime(2026, 6, 5, 19),
        endDateTime: DateTime(2026, 6, 7, 12),
        visibilityRules: const [
          VisibilityRuleEntity.unit(
            unitId: 'unit-1',
            affiliation: Affiliation.visitor,
          ),
          VisibilityRuleEntity.department(
            departmentId: 'department-1',
            integrationType: IntegrationType.integrant,
          ),
          VisibilityRuleEntity.user(userId: '*'),
          VisibilityRuleEntity.church(
            churchId: 'church-1',
            affiliation: Affiliation.member,
          ),
        ],
      );

      expect(model.toJson(), {
        'title': 'Retiro de Jovens',
        'description': 'Programação de fim de semana.',
        'startDateTime': '2026-06-05T19:00:00.000',
        'endDateTime': '2026-06-07T12:00:00.000',
        'visibilityRules': [
          {'type': 'UNIT', 'unitId': 'unit-1', 'affiliation': 'VISITOR'},
          {
            'type': 'DEPARTMENT',
            'departmentId': 'department-1',
            'integrationType': 'INTEGRANT',
          },
          {'type': 'USER', 'userId': '*'},
          {'type': 'CHURCH', 'churchId': 'church-1', 'affiliation': 'MEMBER'},
        ],
      });
    });
  });
}
