import 'package:client/features/calendar/presentation/widgets/user_agenda_day_cell.dart';
import 'package:client/features/home/presentation/screens/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza calendário com o dia atual selecionado', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());

    await tester.pumpWidget(const _CalendarScreenTestApp());

    final todayCell = tester.widget<UserAgendaDayCell>(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(today)}')),
    );

    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('hoje'), findsOneWidget);
    expect(todayCell.isToday, isTrue);
    expect(todayCell.isSelected, isTrue);
  });

  testWidgets('seleciona outro dia visível e atualiza a seleção', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final targetDate = DateUtils.dateOnly(today.add(const Duration(days: 1)));
    final todayKey = ValueKey('user-agenda-day-${_dateKey(today)}');
    final targetKey = ValueKey('user-agenda-day-${_dateKey(targetDate)}');

    await tester.pumpWidget(const _CalendarScreenTestApp());

    expect(
      tester.widget<UserAgendaDayCell>(find.byKey(todayKey)).isSelected,
      isTrue,
    );
    expect(
      tester.widget<UserAgendaDayCell>(find.byKey(targetKey)).isSelected,
      isFalse,
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
    expect(find.text(_formatDayTitle(targetDate)), findsOneWidget);
    expect(find.text('Nada na agenda deste dia.'), findsOneWidget);
  });

  testWidgets(
    'mostra linha de aniversariantes ao selecionar dia com aniversário',
    (tester) async {
      final birthdayDate = DateUtils.dateOnly(
        DateTime.now().add(const Duration(days: 4)),
      );

      await tester.pumpWidget(const _CalendarScreenTestApp());
      await tester.tap(
        find.byKey(ValueKey('user-agenda-day-${_dateKey(birthdayDate)}')),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
      expect(find.text('${birthdayDate.day} | Cecília'), findsOneWidget);
      expect(find.text('${birthdayDate.day} | Marcos'), findsOneWidget);
    },
  );

  testWidgets('mostra evento resumido ao selecionar dia com evento', (
    tester,
  ) async {
    final pastEventDate = DateUtils.dateOnly(
      DateTime.now().subtract(const Duration(days: 3)),
    );

    await tester.pumpWidget(const _CalendarScreenTestApp());
    await tester.tap(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(pastEventDate)}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('Reunião de liderança'), findsOneWidget);
    expect(find.text('Ministério de Ensino'), findsOneWidget);
  });

  testWidgets('mostra mini card de minha escala ao selecionar dia com escala', (
    tester,
  ) async {
    final scaleDate = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 2)),
    );

    await tester.pumpWidget(const _CalendarScreenTestApp());
    await tester.tap(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(scaleDate)}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ensaio geral'), findsOneWidget);
    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Louvor - Vocal, Violão'), findsOneWidget);
  });

  testWidgets('mantém indicadores dos cenários locais principais', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final scaleDate = DateUtils.dateOnly(today.add(const Duration(days: 2)));
    final birthdayDate = DateUtils.dateOnly(today.add(const Duration(days: 4)));

    await tester.pumpWidget(const _CalendarScreenTestApp());

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
  const _CalendarScreenTestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: CalendarScreen()));
  }
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _formatDayTitle(DateTime date) {
  const weekdays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}
