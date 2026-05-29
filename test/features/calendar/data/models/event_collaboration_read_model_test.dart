import 'package:client/features/calendar/data/models/event_collaboration_read_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse collaboration with direct departmentId', () {
    final model = EventCollaborationReadModel.fromJson({
      'id': 'collab-1',
      'calendarEventId': 'event-1',
      'departmentId': 'dep-1',
    });

    expect(model.id, 'collab-1');
    expect(model.calendarEventId, 'event-1');
    expect(model.departmentId, 'dep-1');
    expect(model.department, isNull);
  });

  test('parse collaboration with detailed department', () {
    final model = EventCollaborationReadModel.fromJson({
      'id': 'collab-1',
      'calendarEvent': {'id': 'event-1'},
      'department': {
        'id': 'dep-1',
        'name': 'Louvor',
        'slug': 'louvor',
        'type': 'MINISTRY',
      },
    });

    expect(model.calendarEventId, 'event-1');
    expect(model.departmentId, 'dep-1');
    expect(model.department?.name, 'Louvor');
    expect(model.department?.type, 'MINISTRY');
  });

  test('parse direct department response as collaboration department', () {
    final model = EventCollaborationReadModel.fromJson({
      'id': 'dep-1',
      'unitId': 'unit-1',
      'name': 'Louvor',
      'slug': 'louvor',
      'type': 'ADMINISTRATIVE',
      'profileImageId': 'profile-1',
      'coverImageId': 'cover-1',
    });

    expect(model.id, isEmpty);
    expect(model.calendarEventId, isEmpty);
    expect(model.departmentId, 'dep-1');
    expect(model.department?.id, 'dep-1');
    expect(model.department?.name, 'Louvor');
    expect(model.department?.slug, 'louvor');
    expect(model.department?.type, 'ADMINISTRATIVE');
  });
}
