import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/event_collaboration_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_state.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_day_cell.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/providers/user_agenda_providers.dart';
import 'package:client/features/calendar/providers/user_agenda_view_model_provider.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

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
    await tester.pumpAndSettle();

    expect(find.textContaining('Culto'), findsOneWidget);
    expect(find.textContaining('Confer'), findsWidgets);
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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(emptyDate)}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Essa semana'), findsOneWidget);
    expect(find.text('Nada na agenda deste dia.'), findsNothing);
    expect(find.textContaining('Culto'), findsOneWidget);
  });

  testWidgets('mostra aniversariantes no inicio da semana sem repetir no dia', (
    tester,
  ) async {
    final birthdayDate = DateTime(2026, 6, 7);

    await tester.pumpWidget(
      _CalendarScreenTestApp(today: DateTime(2026, 6, 3)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(birthdayDate)}')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
    expect(find.textContaining('Cec'), findsOneWidget);
    expect(find.textContaining('Marcos'), findsOneWidget);
    expect(find.text('Domingo, 7 jun'), findsNothing);
  });

  testWidgets('troca de mes seleciona o primeiro dia do mes', (tester) async {
    await tester.pumpWidget(
      _CalendarScreenTestApp(today: DateTime(2026, 6, 3)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('user-agenda-next-month')));
    await tester.pumpAndSettle();

    final firstDay = tester.widget<UserAgendaDayCell>(
      find.byKey(const ValueKey('user-agenda-day-2026-07-01')),
    );

    expect(firstDay.isSelected, isTrue);
    expect(find.text('julho 2026'), findsOneWidget);
    expect(find.text('Essa semana'), findsOneWidget);
  });

  testWidgets('mantem indicadores dos cenarios principais', (tester) async {
    final today = DateTime(2026, 6, 3);
    final scaleDate = DateUtils.dateOnly(today.add(const Duration(days: 2)));
    final birthdayDate = DateUtils.dateOnly(today.add(const Duration(days: 4)));

    await tester.pumpWidget(_CalendarScreenTestApp(today: today));
    await tester.pumpAndSettle();

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

  testWidgets('mostra loading discreto enquanto carrega eventos reais', (
    tester,
  ) async {
    final completer = Completer<List<CalendarEventEntity>>();

    await tester.pumpWidget(
      _CalendarScreenTestApp(
        today: DateTime(2026, 6, 3),
        loadEvents: (_) => completer.future,
      ),
    );
    await tester.pump();

    expect(find.text('Carregando agenda...'), findsOneWidget);

    completer.complete(_defaultVisibleEvents(DateTime(2026, 6, 3)));
    await tester.pumpAndSettle();

    expect(find.text('Carregando agenda...'), findsNothing);
    expect(find.textContaining('Culto'), findsOneWidget);
  });

  testWidgets('mostra erro com Tentar novamente', (tester) async {
    var shouldFail = true;

    await tester.pumpWidget(
      _CalendarScreenTestApp(
        today: DateTime(2026, 6, 3),
        startWithError: true,
        loadEvents: (_) async {
          if (shouldFail) return const [];
          return _defaultVisibleEvents(DateTime(2026, 6, 3));
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Erro ao carregar eventos visiveis.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('Erro ao carregar eventos visiveis.'), findsNothing);
    expect(find.textContaining('Culto'), findsOneWidget);
  });

  testWidgets('tocar em card de evento real abre o detalhe com id real', (
    tester,
  ) async {
    String? loadedEventId;

    await tester.pumpWidget(
      _CalendarScreenTestApp(
        today: DateTime(2026, 6, 3),
        loadDetail: (eventId) async {
          loadedEventId = eventId;
          return CalendarEventEntity(
            id: eventId,
            title: 'Detalhe do evento real',
            description: 'Detalhe aberto pela agenda.',
            startDateTime: DateTime(2026, 6, 3, 19),
            endDateTime: DateTime(2026, 6, 3, 21),
            type: CalendarEventType.unit,
            unitId: 'unit-1',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Culto'));
    await tester.tap(find.textContaining('Culto'));
    await tester.pumpAndSettle();

    expect(loadedEventId, 'event-today');
    expect(find.text('Detalhe do evento real'), findsOneWidget);
  });

  testWidgets('card de aniversario nao abre detalhe de evento', (tester) async {
    var loadCount = 0;
    final birthdayDate = DateTime(2026, 6, 7);

    await tester.pumpWidget(
      _CalendarScreenTestApp(
        today: DateTime(2026, 6, 3),
        loadDetail: (eventId) async {
          loadCount++;
          return _eventDetail(eventId);
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('user-agenda-day-${_dateKey(birthdayDate)}')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Cec'));
    await tester.pumpAndSettle();

    expect(loadCount, 0);
    expect(find.text('Detalhe do evento real'), findsNothing);
  });

  testWidgets('card de escala pessoal nao abre detalhe de evento', (
    tester,
  ) async {
    var loadCount = 0;

    await tester.pumpWidget(
      _CalendarScreenTestApp(
        today: DateTime(2026, 6, 3),
        loadDetail: (eventId) async {
          loadCount++;
          return _eventDetail(eventId);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ensaio geral'));
    await tester.tap(find.text('Ensaio geral'));
    await tester.pumpAndSettle();

    expect(loadCount, 0);
    expect(find.text('Detalhe do evento real'), findsNothing);
  });
}

class _CalendarScreenTestApp extends StatelessWidget {
  const _CalendarScreenTestApp({
    required this.today,
    this.loadEvents,
    this.loadDetail,
    this.startWithError = false,
  });

  final DateTime today;
  final bool startWithError;
  final Future<List<CalendarEventEntity>> Function(
    VisibleCalendarEventsRequest request,
  )?
  loadEvents;
  final Future<CalendarEventEntity> Function(String eventId)? loadDetail;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        userAgendaTodayProvider.overrideWithValue(today),
        if (startWithError)
          userAgendaViewModelProvider.overrideWithBuild((ref, notifier) async {
            return _emptyAgendaState(
              today,
              errorMessage: 'Erro ao carregar eventos visiveis.',
            );
          }),
        visibleCalendarEventsProvider.overrideWith((ref, request) async {
          final loader = loadEvents;
          if (loader != null) return loader(request);
          return _defaultVisibleEvents(today);
        }),
        calendarEventDetailProvider.overrideWith((ref, eventId) {
          return loadDetail?.call(eventId) ??
              Future.value(_eventDetail(eventId));
        }),
        calendarEventCollaboratorsProvider.overrideWith(
          (ref, eventId) async => const <EventCollaborationEntity>[],
        ),
        sessionPermissionsProvider.overrideWith(
          (ref) async => const SessionPermissions(
            isAuthenticated: true,
            affiliation: Affiliation.member,
            activeUnitId: 'unit-1',
            hasMembership: true,
            integrations: [],
            isUnitAdmin: false,
          ),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: CalendarScreen())),
    );
  }
}

CalendarEventEntity _eventDetail(String eventId) {
  return CalendarEventEntity(
    id: eventId,
    title: 'Detalhe do evento real',
    description: 'Detalhe aberto pela agenda.',
    startDateTime: DateTime(2026, 6, 3, 19),
    endDateTime: DateTime(2026, 6, 3, 21),
    type: CalendarEventType.unit,
    unitId: 'unit-1',
  );
}

UserAgendaState _emptyAgendaState(DateTime today, {String? errorMessage}) {
  final normalizedToday = DateUtils.dateOnly(today);
  final visibleWeekStart = normalizedToday.subtract(
    Duration(days: normalizedToday.weekday % DateTime.daysPerWeek),
  );

  return UserAgendaState(
    today: normalizedToday,
    focusedMonth: DateTime(normalizedToday.year, normalizedToday.month),
    selectedDate: normalizedToday,
    visibleWeekStart: visibleWeekStart,
    visibleWeekEnd: visibleWeekStart.add(
      const Duration(days: DateTime.daysPerWeek - 1),
    ),
    weeklyGroups: List.generate(DateTime.daysPerWeek, (index) {
      return UserAgendaDayGroupEntity(
        date: visibleWeekStart.add(Duration(days: index)),
      );
    }),
    markersByDate: const {},
    errorMessage: errorMessage,
    isUsingRealEvents: true,
  );
}

List<CalendarEventEntity> _defaultVisibleEvents(DateTime today) {
  final normalizedToday = DateUtils.dateOnly(today);
  final multiDayStart = normalizedToday.add(const Duration(days: 1, hours: 19));

  return [
    CalendarEventEntity(
      id: 'event-today',
      title: 'Culto de celebracao',
      startDateTime: normalizedToday.add(const Duration(hours: 19)),
      endDateTime: normalizedToday.add(const Duration(hours: 21)),
      type: CalendarEventType.unit,
      unitId: 'unit-1',
    ),
    CalendarEventEntity(
      id: 'event-multi-day',
      title: 'Conferencia de verao',
      startDateTime: multiDayStart,
      endDateTime: multiDayStart.add(const Duration(days: 2, hours: 3)),
      type: CalendarEventType.department,
      departmentId: 'dep-1',
    ),
  ];
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
