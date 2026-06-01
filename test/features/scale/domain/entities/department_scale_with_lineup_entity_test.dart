import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserva escala, evento, lineupId e formacao carregada', () {
    const lineup = LineupEntity(id: 'lineup-1', name: 'Louvor');
    final entity = DepartmentScaleWithLineupEntity(
      scale: _departmentScale,
      lineupState: DepartmentScaleLineupLoadState.loaded,
      lineup: lineup,
    );

    expect(entity.scale.calendarEvent, _calendarEvent);
    expect(entity.scale.scale.lineupId, 'lineup-1');
    expect(entity.lineup, lineup);
    expect(entity.hasLineupFailure, isFalse);
  });

  test('representa falha parcial de formacao sem perder a escala', () {
    final entity = DepartmentScaleWithLineupEntity(
      scale: _departmentScale,
      lineupState: DepartmentScaleLineupLoadState.failed,
    );

    expect(entity.scale, _departmentScale);
    expect(entity.lineup, isNull);
    expect(entity.hasLineupFailure, isTrue);
  });

  test('compara escala, estado e formacao', () {
    const lineup = LineupEntity(id: 'lineup-1', name: 'Louvor');

    expect(
      DepartmentScaleWithLineupEntity(
        scale: _departmentScale,
        lineupState: DepartmentScaleLineupLoadState.loaded,
        lineup: lineup,
      ),
      DepartmentScaleWithLineupEntity(
        scale: _departmentScale,
        lineupState: DepartmentScaleLineupLoadState.loaded,
        lineup: lineup,
      ),
    );
  });
}

final _calendarEvent = CalendarEventEntity(
  id: 'event-1',
  title: 'Culto',
  startDateTime: _startDateTime,
  endDateTime: _endDateTime,
  type: CalendarEventType.department,
  departmentId: 'dep-1',
);

final _departmentScale = DepartmentCalendarEventScaleEntity(
  scale: const CalendarEventScaleEntity(
    id: 'scale-1',
    lineupId: 'lineup-1',
    type: CalendarEventScaleType.owner,
    calendarEventId: 'event-1',
  ),
  calendarEvent: _calendarEvent,
);

final _startDateTime = DateTime(2026, 6, 7, 18);
final _endDateTime = DateTime(2026, 6, 7, 20);
