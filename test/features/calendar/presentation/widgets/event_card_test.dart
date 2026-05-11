import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/presentation/widgets/event_card.dart';
import 'package:client/features/calendar/presentation/widgets/event_date_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatEventDateRange', () {
    test('formata periodo em PT-BR abreviado', () {
      expect(
        formatEventDateRange(
          DateTime(2026, 5, 10, 18),
          DateTime(2026, 5, 10, 20, 30),
        ),
        '10 mai 18:00 - 10 mai 20:30',
      );
    });
  });

  testWidgets('renderiza titulo, periodo e descricao', (tester) async {
    await tester.pumpWidget(_build(event: _event()));

    expect(find.text('Culto de Celebração'), findsOneWidget);
    expect(find.text('10 mai 18:00 - 10 mai 20:00'), findsOneWidget);
    expect(find.text('Encontro aberto para toda a unidade.'), findsOneWidget);
  });

  testWidgets('omite descricao quando evento nao possui descricao', (
    tester,
  ) async {
    await tester.pumpWidget(_build(event: _event(description: null)));

    expect(find.text('Culto de Celebração'), findsOneWidget);
    expect(find.text('Encontro aberto para toda a unidade.'), findsNothing);
  });

  testWidgets('exibe badge para evento de unidade', (tester) async {
    await tester.pumpWidget(
      _build(event: _event(type: CalendarEventType.unit)),
    );

    expect(find.text('Unidade'), findsOneWidget);
    expect(find.text('Departamento'), findsNothing);
  });

  testWidgets('exibe badge para evento de departamento', (tester) async {
    await tester.pumpWidget(
      _build(event: _event(type: CalendarEventType.department)),
    );

    expect(find.text('Departamento'), findsOneWidget);
    expect(find.text('Unidade'), findsNothing);
  });
}

Widget _build({required CalendarEventEntity event}) {
  return MaterialApp(
    home: Scaffold(body: EventCard(event: event)),
  );
}

CalendarEventEntity _event({
  CalendarEventType type = CalendarEventType.unit,
  String? description = 'Encontro aberto para toda a unidade.',
}) {
  return CalendarEventEntity(
    id: 'event-1',
    title: 'Culto de Celebração',
    description: description,
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: type,
    unitId: type == CalendarEventType.unit ? 'unit-1' : null,
    departmentId: type == CalendarEventType.department ? 'dep-1' : null,
  );
}
