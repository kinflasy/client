import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_state.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/providers/user_agenda_providers.dart';
import 'package:client/features/calendar/providers/user_agenda_view_model_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late List<CalendarEventEntity> visibleEvents;
  late List<VisibleCalendarEventsRequest> visibleRequests;

  setUp(() {
    visibleEvents = _defaultVisibleEvents();
    visibleRequests = [];
    container = ProviderContainer(
      overrides: [
        userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
        visibleCalendarEventsProvider.overrideWith((ref, request) async {
          visibleRequests.add(request);
          return visibleEvents;
        }),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<UserAgendaState> readState() {
    return container.read(userAgendaViewModelProvider.future);
  }

  test('estado inicial seleciona hoje e mostra a semana inteira', () async {
    final state = await readState();

    expect(state.today, DateTime(2026, 6, 3));
    expect(state.selectedDate, DateTime(2026, 6, 3));
    expect(state.focusedMonth, DateTime(2026, 6));
    expect(state.visibleWeekStart, DateTime(2026, 5, 31));
    expect(state.visibleWeekEnd, DateTime(2026, 6, 6));
    expect(state.weeklyGroups.map((group) => group.date), [
      DateTime(2026, 5, 31),
      DateTime(2026, 6),
      DateTime(2026, 6, 2),
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
      DateTime(2026, 6, 5),
      DateTime(2026, 6, 6),
    ]);
  });

  test('estado inicial nao define alvo de foco', () async {
    final state = await readState();

    expect(state.focusTargetDate, isNull);
  });

  test('selecionar dia pelo usuario define alvo de foco', () async {
    await readState();
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    await notifier.selectDate(DateTime(2026, 6, 5, 18));
    final state = container.read(userAgendaViewModelProvider).requireValue;

    expect(state.selectedDate, DateTime(2026, 6, 5));
    expect(state.focusTargetDate, DateTime(2026, 6, 5));
    expect(state.visibleWeekStart, DateTime(2026, 5, 31));
    expect(state.visibleWeekEnd, DateTime(2026, 6, 6));
  });

  test('troca para mes anterior selecionando o primeiro dia do mes', () async {
    await readState();
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    await notifier.goToPreviousMonth();
    final state = container.read(userAgendaViewModelProvider).requireValue;

    expect(state.focusedMonth, DateTime(2026, 5));
    expect(state.selectedDate, DateTime(2026, 5));
    expect(state.visibleWeekStart, DateTime(2026, 4, 26));
    expect(state.visibleWeekEnd, DateTime(2026, 5, 2));
    expect(state.focusTargetDate, isNull);
  });

  test('troca para proximo mes selecionando o primeiro dia do mes', () async {
    await readState();
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    await notifier.goToNextMonth();
    final state = container.read(userAgendaViewModelProvider).requireValue;

    expect(state.focusedMonth, DateTime(2026, 7));
    expect(state.selectedDate, DateTime(2026, 7));
    expect(state.visibleWeekStart, DateTime(2026, 6, 28));
    expect(state.visibleWeekEnd, DateTime(2026, 7, 4));
    expect(state.focusTargetDate, isNull);
  });

  test('botao Hoje retorna para mes e semana atuais', () async {
    await readState();
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    await notifier.goToNextMonth();
    await notifier.goToToday();
    final state = container.read(userAgendaViewModelProvider).requireValue;

    expect(state.focusedMonth, DateTime(2026, 6));
    expect(state.selectedDate, DateTime(2026, 6, 3));
    expect(state.visibleWeekStart, DateTime(2026, 5, 31));
    expect(state.visibleWeekEnd, DateTime(2026, 6, 6));
    expect(state.focusTargetDate, isNull);
  });

  test('abertura inicial carrega pelo intervalo mensal visivel', () async {
    await readState();

    expect(visibleRequests, [
      VisibleCalendarEventsRequest(
        start: DateTime(2026, 5, 31),
        end: DateTime(2026, 7, 4),
      ),
    ]);
  });

  test('trocar de mes recarrega com novo intervalo', () async {
    await readState();
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    await notifier.goToNextMonth();

    expect(visibleRequests, [
      VisibleCalendarEventsRequest(
        start: DateTime(2026, 5, 31),
        end: DateTime(2026, 7, 4),
      ),
      VisibleCalendarEventsRequest(
        start: DateTime(2026, 6, 28),
        end: DateTime(2026, 8, 1),
      ),
    ]);
  });

  test('weeklyGroups contem somente a semana selecionada', () async {
    visibleEvents = [
      ..._defaultVisibleEvents(),
      _calendarEvent(
        id: 'event-future',
        title: 'Evento fora da semana',
        type: CalendarEventType.unit,
        unitId: 'unit-1',
        startDateTime: DateTime(2026, 6, 20, 18),
        endDateTime: DateTime(2026, 6, 20, 20),
      ),
    ];

    final state = await readState();

    expect(state.weeklyGroups.map((group) => group.date), [
      DateTime(2026, 5, 31),
      DateTime(2026, 6),
      DateTime(2026, 6, 2),
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
      DateTime(2026, 6, 5),
      DateTime(2026, 6, 6),
    ]);
    expect(
      state.weeklyGroups.expand((group) => group.items).map((item) => item.id),
      isNot(contains('event-future')),
    );
  });

  test(
    'markersByDate contem eventos reais fora da semana selecionada',
    () async {
      visibleEvents = [
        _calendarEvent(
          id: 'event-future',
          title: 'Evento fora da semana',
          type: CalendarEventType.unit,
          unitId: 'unit-1',
          startDateTime: DateTime(2026, 6, 20, 18),
          endDateTime: DateTime(2026, 6, 20, 20),
        ),
      ];

      final state = await readState();

      expect(state.markersByDate[DateTime(2026, 6, 20)]?.hasEvent, isTrue);
      expect(
        state.weeklyGroups
            .expand((group) => group.items)
            .map((item) => item.id),
        isNot(contains('event-future')),
      );
    },
  );

  test('evento real de multiplos dias aparece nos dias locais', () async {
    final state = await readState();
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    expect(state.markersByDate[DateTime(2026, 6, 5)]?.hasEvent, isTrue);
    expect(state.markersByDate[DateTime(2026, 6, 6)]?.hasEvent, isTrue);
    expect(state.markersByDate[DateTime(2026, 6, 7)]?.hasEvent, isTrue);

    await notifier.selectDate(DateTime(2026, 6, 7));
    final sundayState = container
        .read(userAgendaViewModelProvider)
        .requireValue;
    final sundayItems = sundayState.weeklyGroups
        .singleWhere((group) => group.date == DateTime(2026, 6, 7))
        .items;

    expect(sundayItems.map((item) => item.id), contains('event-multi-day'));
  });

  test('request da agenda calcula intervalo mensal visivel normalizado', () {
    final request = UserAgendaItemsRequest.forFocusedMonth(
      DateTime(2026, 6, 18, 14),
    );

    expect(request.start, DateTime(2026, 5, 31));
    expect(request.end, DateTime(2026, 7, 4));
  });

  test('converte evento real de unidade para item de agenda', () {
    final event = _calendarEvent(
      id: 'event-unit',
      title: 'Culto especial',
      type: CalendarEventType.unit,
      unitId: 'unit-1',
    );

    final item = mapCalendarEventToUserAgendaItem(event);

    expect(item.id, 'event-unit');
    expect(item.title, 'Culto especial');
    expect(item.startDateTime, event.startDateTime);
    expect(item.endDateTime, event.endDateTime);
    expect(item.origin, 'Igreja');
  });

  test('converte evento real de departamento para item de agenda', () {
    final event = _calendarEvent(
      id: 'event-department',
      title: 'Ensaio',
      type: CalendarEventType.department,
      departmentId: 'dep-1',
    );

    final item = mapCalendarEventToUserAgendaItem(event);

    expect(item.id, 'event-department');
    expect(item.origin, 'Departamento');
  });

  test('fonte real preserva id do evento e nao inclui eventos demo', () async {
    final event = _calendarEvent(
      id: 'real-event-1',
      title: 'Evento real',
      type: CalendarEventType.unit,
      unitId: 'unit-1',
    );
    container.dispose();
    container = ProviderContainer(
      overrides: [
        userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
        visibleCalendarEventsProvider.overrideWith(
          (ref, request) async => [event],
        ),
      ],
    );

    final items = await container.read(
      userAgendaItemsProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(
      items.whereType<UserAgendaEventItemEntity>().map((item) => item.id),
      ['real-event-1'],
    );
    expect(items.map((item) => item.id), isNot(contains('demo-event-today')));
    expect(items.map((item) => item.id), isNot(contains('demo-event-scale')));
  });

  test(
    'fonte real mantem aniversariantes e escala local suplementar',
    () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
          visibleCalendarEventsProvider.overrideWith(
            (ref, request) async => const [],
          ),
        ],
      );

      final items = await container.read(
        userAgendaItemsProvider(
          UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
        ).future,
      );

      expect(items.whereType<UserAgendaBirthdayItemEntity>(), hasLength(3));
      expect(
        items.whereType<UserAgendaPersonalScaleItemEntity>(),
        hasLength(1),
      );
    },
  );
}

CalendarEventEntity _calendarEvent({
  required String id,
  required String title,
  required CalendarEventType type,
  String? unitId,
  String? departmentId,
  DateTime? startDateTime,
  DateTime? endDateTime,
}) {
  return CalendarEventEntity(
    id: id,
    title: title,
    startDateTime: startDateTime ?? DateTime(2026, 6, 7, 18),
    endDateTime: endDateTime ?? DateTime(2026, 6, 7, 20),
    type: type,
    unitId: unitId,
    departmentId: departmentId,
  );
}

List<CalendarEventEntity> _defaultVisibleEvents() {
  return [
    _calendarEvent(
      id: 'event-today',
      title: 'Culto especial',
      type: CalendarEventType.unit,
      unitId: 'unit-1',
      startDateTime: DateTime(2026, 6, 3, 19),
      endDateTime: DateTime(2026, 6, 3, 21),
    ),
    _calendarEvent(
      id: 'event-multi-day',
      title: 'Conferencia',
      type: CalendarEventType.department,
      departmentId: 'dep-1',
      startDateTime: DateTime(2026, 6, 5, 19, 30),
      endDateTime: DateTime(2026, 6, 7, 10),
    ),
  ];
}
