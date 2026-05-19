import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/presentation/widgets/event_card.dart';
import 'package:client/features/calendar/presentation/widgets/event_date_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatEventDateRange', () {
    test('formata período em PT-BR abreviado', () {
      expect(
        formatEventDateRange(
          DateTime(2026, 5, 10, 18),
          DateTime(2026, 5, 10, 20, 30),
        ),
        '10 mai 18:00 - 10 mai 20:30',
      );
    });
  });

  testWidgets('renderiza título, período, organizador e descrição', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(event: _event(), organizerLabel: 'Unidade Central'),
    );

    expect(find.text('Unidade Central'), findsOneWidget);
    expect(find.text('Culto de Celebração'), findsOneWidget);
    expect(find.text('10 mai 18:00 - 10 mai 20:00'), findsOneWidget);
    expect(find.text('Encontro aberto para toda a unidade.'), findsOneWidget);
    expect(find.text('... abrir'), findsOneWidget);
  });

  testWidgets('omite descrição quando evento não possui descrição', (
    tester,
  ) async {
    await tester.pumpWidget(_build(event: _event(description: null)));

    expect(find.text('Culto de Celebração'), findsOneWidget);
    expect(find.text('Encontro aberto para toda a unidade.'), findsNothing);
  });

  testWidgets('menu de três pontos chama edição', (tester) async {
    var editCalled = false;
    var deleteCalled = false;
    await tester.pumpWidget(
      _build(
        event: _event(),
        organizerLabel: 'Unidade Central - Louvor',
        onEdit: () => editCalled = true,
        onDelete: () => deleteCalled = true,
      ),
    );

    expect(find.text('Unidade Central - Louvor'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(editCalled, isTrue);
    expect(deleteCalled, isFalse);
  });

  testWidgets('menu de três pontos chama exclusão', (tester) async {
    var editCalled = false;
    var deleteCalled = false;
    await tester.pumpWidget(
      _build(
        event: _event(),
        onEdit: () => editCalled = true,
        onDelete: () => deleteCalled = true,
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(editCalled, isFalse);
    expect(deleteCalled, isTrue);
  });

  testWidgets('menu de três pontos chama duplicação', (tester) async {
    var duplicateCalled = false;
    await tester.pumpWidget(
      _build(event: _event(), onDuplicate: () => duplicateCalled = true),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Duplicar'), findsOneWidget);

    await tester.tap(find.text('Duplicar'));
    await tester.pumpAndSettle();

    expect(duplicateCalled, isTrue);
  });
}

Widget _build({
  required CalendarEventEntity event,
  String? organizerLabel,
  VoidCallback? onEdit,
  VoidCallback? onDuplicate,
  VoidCallback? onDelete,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: EventCard(
          event: event,
          organizerLabel: organizerLabel,
          onEdit: onEdit,
          onDuplicate: onDuplicate,
          onDelete: onDelete,
        ),
      ),
    ),
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
