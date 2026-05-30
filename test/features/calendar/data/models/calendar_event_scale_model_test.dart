import 'package:client/features/calendar/data/models/calendar_event_scale_read_model.dart';
import 'package:client/features/calendar/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_scale_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('request serializes only lineupId', () {
    const request = CalendarEventScaleRequestModel(lineupId: 'lineup-1');

    expect(request.toJson(), {'lineupId': 'lineup-1'});
  });

  test('read model parses owner scale with calendar event id', () {
    final model = CalendarEventScaleReadModel.fromJson(const {
      'id': 'scale-1',
      'lineupId': 'lineup-1',
      'type': 'OWNER',
      'calendarEventId': 'event-1',
    });

    final entity = model.toEntity();

    expect(entity.id, 'scale-1');
    expect(entity.lineupId, 'lineup-1');
    expect(entity.type, CalendarEventScaleType.owner);
    expect(entity.calendarEventId, 'event-1');
    expect(entity.collaborationId, isNull);
  });

  test('read model parses collaborator scale without owner fields', () {
    final model = CalendarEventScaleReadModel.fromJson(const {
      'id': 'scale-2',
      'lineup': {'id': 'lineup-2'},
      'type': 'COLLABORATOR',
      'collaboration': {'id': 'collab-1'},
    });

    final entity = model.toEntity();

    expect(entity.id, 'scale-2');
    expect(entity.lineupId, 'lineup-2');
    expect(entity.type, CalendarEventScaleType.collaborator);
    expect(entity.calendarEventId, isNull);
    expect(entity.collaborationId, 'collab-1');
  });
}
