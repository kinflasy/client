import 'package:client/features/scale/data/models/calendar_event_scale_read_model.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
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

  test('department read model parses detailing calendar event', () {
    final model = DepartmentCalendarEventScaleReadModel.fromJson(const {
      'id': 'scale-1',
      'lineupId': 'lineup-1',
      'type': 'OWNER',
      'calendarEventId': 'event-1',
      'calendarEvent': {
        'id': 'event-1',
        'title': 'Culto da manhã',
        'startDateTime': '2026-07-20T09:00:00',
        'endDateTime': '2026-07-20T11:00:00',
        'type': 'DEPARTMENT',
        'departmentId': 'dep-1',
      },
    });

    final entity = model.toEntity();

    expect(entity.scale.id, 'scale-1');
    expect(entity.scale.type, CalendarEventScaleType.owner);
    expect(entity.scale.calendarEventId, 'event-1');
    expect(entity.calendarEvent.id, 'event-1');
    expect(entity.calendarEvent.title, 'Culto da manhã');
  });

  test('department read model preserves owner calendarEventId', () {
    final entity = DepartmentCalendarEventScaleReadModel.fromJson(const {
      'id': 'scale-1',
      'lineupId': 'lineup-1',
      'type': 'OWNER',
      'calendarEventId': 'event-1',
      'calendarEvent': {
        'id': 'event-1',
        'title': 'Culto',
        'startDateTime': '2026-07-20T09:00:00',
        'endDateTime': '2026-07-20T11:00:00',
        'type': 'DEPARTMENT',
        'departmentId': 'dep-1',
      },
    }).toEntity();

    expect(entity.scale.calendarEventId, 'event-1');
  });

  test('department read model accepts collaborator scale', () {
    final entity = DepartmentCalendarEventScaleReadModel.fromJson(const {
      'id': 'scale-2',
      'lineupId': 'lineup-2',
      'type': 'COLLABORATOR',
      'collaborationId': 'collab-1',
      'calendarEvent': {
        'id': 'event-1',
        'title': 'Conferência',
        'startDateTime': '2026-08-01T19:00:00',
        'endDateTime': '2026-08-01T21:00:00',
        'type': 'UNIT',
        'unitId': 'unit-1',
      },
    }).toEntity();

    expect(entity.scale.type, CalendarEventScaleType.collaborator);
    expect(entity.scale.collaborationId, 'collab-1');
    expect(entity.calendarEvent.title, 'Conferência');
  });

  test('department read model rejects scale without calendarEvent', () {
    expect(
      () => DepartmentCalendarEventScaleReadModel.fromJson(const {
        'id': 'scale-1',
        'lineupId': 'lineup-1',
        'type': 'OWNER',
      }),
      throwsFormatException,
    );
  });
}
