import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/presentation/widgets/department_scale_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows event date title and chevron', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DepartmentScaleCard(scale: _scale)),
      ),
    );

    expect(find.text('Dom, 19 jul - 09:00'), findsOneWidget);
    expect(find.text('Culto da manhã'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('handles tap without built-in navigation', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(scale: _scale, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('Culto da manhã'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}

final _scale = DepartmentCalendarEventScaleEntity(
  scale: const CalendarEventScaleEntity(
    id: 'scale-1',
    lineupId: 'lineup-1',
    type: CalendarEventScaleType.owner,
    calendarEventId: 'event-1',
  ),
  calendarEvent: CalendarEventEntity(
    id: 'event-1',
    title: 'Culto da manhã',
    startDateTime: DateTime(2026, 7, 19, 9),
    endDateTime: DateTime(2026, 7, 19, 11),
    type: CalendarEventType.department,
    departmentId: 'dep-1',
  ),
);
