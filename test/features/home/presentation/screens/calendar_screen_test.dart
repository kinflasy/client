import 'package:client/features/calendar/presentation/widgets/user_agenda_day_cell.dart';
import 'package:client/features/calendar/providers/user_agenda_providers.dart';
import 'package:client/features/home/presentation/screens/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra lista semanal com Essa semana, nao lista diaria', (
    tester,
  ) async {
    final today = DateTime(2026, 6, 3);

    await tester.pumpWidget(_CalendarScreenTestApp(today: today));

    final todayCell = tester.widget<UserAgendaDayCell>(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(today)}')),
    );

    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Essa semana'), findsOneWidget);
    expect(find.text('hoje'), findsNothing);
    expect(todayCell.isToday, isTrue);
    expect(todayCell.isSelected, isTrue);
  });

  testWidgets('abertura inicial nao faz foco automatico em hoje', (
    tester,
  ) async {
    await tester.pumpWidget(
      _CalendarScreenTestApp(today: DateTime(2026, 6, 3)),
    );
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

    expect(scrollable.position.pixels, 0);
  });

  testWidgets('semana renderiza itens de mais de um dia', (tester) async {
    await tester.pumpWidget(
      _CalendarScreenTestApp(today: DateTime(2026, 6, 3)),
    );

    expect(find.text('Culto de celebração'), findsOneWidget);
    expect(find.text('Conferência de verão'), findsWidgets);
    expect(find.text('Ensaio geral'), findsOneWidget);
  });

  testWidgets('tocar em dia com item seleciona o dia e mantem lista semanal', (
    tester,
  ) async {
    final today = DateTime(2026, 6, 3);
    final targetDate = DateTime(2026, 6, 5);
    final todayKey = ValueKey('user-agenda-day-${_dateKey(today)}');
    final targetKey = ValueKey('user-agenda-day-${_dateKey(targetDate)}');

    await tester.pumpWidget(_CalendarScreenTestApp(today: today));

    expect(
      tester.widget<UserAgendaDayCell>(find.byKey(todayKey)).isSelected,
      isTrue,
    );

    await tester.tap(find.byKey(targetKey));
    await tester.pumpAndSettle();

    expect(
      tester.widget<UserAgendaDayCell>(find.byKey(todayKey)).isSelected,
      isFalse,
    );
    expect(
      tester.widget<UserAgendaDayCell>(find.byKey(targetKey)).isSelected,
      isTrue,
    );
    expect(find.text('Essa semana'), findsOneWidget);
    expect(find.text('Ensaio geral'), findsOneWidget);
  });

  testWidgets('tocar em dia sem item nao troca para vazio diario', (
    tester,
  ) async {
    final emptyDate = DateTime(2026, 6, 2);

    await tester.pumpWidget(
      _CalendarScreenTestApp(today: DateTime(2026, 6, 3)),
    );
    await tester.tap(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(emptyDate)}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Essa semana'), findsOneWidget);
    expect(find.text('Nada na agenda deste dia.'), findsNothing);
    expect(find.text('Culto de celebração'), findsOneWidget);
  });

  testWidgets('mostra aniversariantes no inicio da semana sem repetir no dia', (
    tester,
  ) async {
    final birthdayDate = DateTime(2026, 6, 7);

    await tester.pumpWidget(
      _CalendarScreenTestApp(today: DateTime(2026, 6, 3)),
    );
    await tester.tap(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(birthdayDate)}')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
    expect(find.text('7 | Cecília'), findsOneWidget);
    expect(find.text('7 | Marcos'), findsOneWidget);
    expect(find.text('Domingo, 7 jun'), findsNothing);
  });

  testWidgets('troca de mes seleciona o primeiro dia do mes', (tester) async {
    await tester.pumpWidget(
      _CalendarScreenTestApp(today: DateTime(2026, 6, 3)),
    );

    await tester.tap(find.byKey(const ValueKey('user-agenda-next-month')));
    await tester.pumpAndSettle();

    final firstDay = tester.widget<UserAgendaDayCell>(
      find.byKey(const ValueKey('user-agenda-day-2026-07-01')),
    );

    expect(firstDay.isSelected, isTrue);
    expect(find.text('julho 2026'), findsOneWidget);
    expect(find.text('Essa semana'), findsOneWidget);
  });

  testWidgets('mantem indicadores dos cenarios locais principais', (
    tester,
  ) async {
    final today = DateTime(2026, 6, 3);
    final scaleDate = DateUtils.dateOnly(today.add(const Duration(days: 2)));
    final birthdayDate = DateUtils.dateOnly(today.add(const Duration(days: 4)));

    await tester.pumpWidget(_CalendarScreenTestApp(today: today));

    final scaleCell = tester.widget<UserAgendaDayCell>(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(scaleDate)}')),
    );
    final birthdayCell = tester.widget<UserAgendaDayCell>(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(birthdayDate)}')),
    );

    expect(scaleCell.markers.hasEvent, isTrue);
    expect(scaleCell.markers.hasUserScale, isTrue);
    expect(birthdayCell.markers.hasBirthday, isTrue);
  });
}

class _CalendarScreenTestApp extends StatelessWidget {
  const _CalendarScreenTestApp({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [userAgendaTodayProvider.overrideWithValue(today)],
      child: const MaterialApp(home: Scaffold(body: CalendarScreen())),
    );
  }
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
