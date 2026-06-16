import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/person_birthday_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_state.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/providers/user_agenda_providers.dart';
import 'package:client/features/calendar/providers/user_agenda_view_model_provider.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/scale_item_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _MockCalendarEventRepository extends Mock
    implements CalendarEventRepository {}

Future<T> _readFutureProvider<T>(
  ProviderContainer container,
  dynamic provider,
) async {
  final completer = Completer<T>();
  final subscription = container.listen<AsyncValue<T>>(provider, (
    previous,
    next,
  ) {
    if (next.hasValue && !completer.isCompleted) {
      completer.complete(next.requireValue);
    } else if (next.hasError && !completer.isCompleted) {
      completer.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);

  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}

ProviderContainer _buildPersonalScalesContainer({
  required List<CalendarEventEntity> visibleEvents,
  required List<DepartmentCalendarEventScaleEntity> myScales,
  required CalendarEventRepository calendarEventRepository,
  required DepartmentRepository departmentRepository,
  LoggedUserProfileEntity? loggedUserProfile,
}) {
  return ProviderContainer(
    overrides: [
      userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
      visibleCalendarEventsProvider.overrideWith((ref, request) async {
        return visibleEvents;
      }),
      myCalendarScalesProvider.overrideWith((ref, request) async {
        return myScales;
      }),
      editLoggedUserInitialDataProvider.overrideWith((ref) async {
        return loggedUserProfile ??
            const LoggedUserProfileEntity(
              id: 'person-1',
              fullName: 'Pessoa Logada',
              gender: 'M',
            );
      }),
      calendarEventRepositoryProvider.overrideWithValue(
        calendarEventRepository,
      ),
      departmentRepositoryProvider.overrideWithValue(departmentRepository),
    ],
  );
}

DepartmentCalendarEventScaleEntity _personalScaleEvent({
  required String scaleId,
  required String lineupId,
  required String eventId,
  required String departmentId,
  required String title,
  DateTime? startDateTime,
  DateTime? endDateTime,
}) {
  return DepartmentCalendarEventScaleEntity(
    scale: CalendarEventScaleEntity(
      id: scaleId,
      lineupId: lineupId,
      type: CalendarEventScaleType.owner,
      calendarEventId: eventId,
    ),
    calendarEvent: CalendarEventEntity(
      id: eventId,
      title: title,
      startDateTime: startDateTime ?? DateTime(2026, 6, 7, 18),
      endDateTime: endDateTime ?? DateTime(2026, 6, 7, 20),
      type: CalendarEventType.department,
      departmentId: departmentId,
    ),
  );
}

LineupEntity _lineupWithRoles({
  required String lineupId,
  required String name,
  required List<LineupItemEntity> items,
}) {
  return LineupEntity(id: lineupId, name: name, items: items);
}

LineupItemEntity _lineupItem({
  required String id,
  required String lineupId,
  required String roleId,
  required String description,
  String? roleName,
}) {
  return LineupItemEntity(
    id: id,
    lineupId: lineupId,
    roleId: roleId,
    description: description,
    role: roleName == null
        ? null
        : RoleEntity(id: roleId, name: roleName, slug: roleName.toLowerCase()),
  );
}

void main() {
  late ProviderContainer container;
  late List<CalendarEventEntity> visibleEvents;
  late List<VisibleCalendarEventsRequest> visibleRequests;
  late List<PersonBirthdayEntity> unitBirthdays;
  late List<UnitBirthdaysRequest> birthdayRequests;
  late Object? birthdayFailure;

  setUp(() {
    visibleEvents = _defaultVisibleEvents();
    visibleRequests = [];
    unitBirthdays = const [];
    birthdayRequests = [];
    birthdayFailure = null;
    container = ProviderContainer(
      overrides: [
        userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
        visibleCalendarEventsProvider.overrideWith((ref, request) async {
          visibleRequests.add(request);
          return visibleEvents;
        }),
        unitBirthdaysProvider.overrideWith((ref, request) {
          birthdayRequests.add(request);
          final failure = birthdayFailure;
          if (failure != null) {
            return Future<List<PersonBirthdayEntity>>.error(failure);
          }
          return unitBirthdays;
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
        unitBirthdaysProvider.overrideWith((ref, request) async => const []),
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

  test('fonte real usa aniversariantes reais sem escala demo local', () async {
    unitBirthdays = const [
      PersonBirthdayEntity(
        id: 'person-maria',
        name: 'Maria',
        birthdayMonth: 6,
        birthdayDay: 7,
      ),
    ];

    final items = await container.read(
      userAgendaItemsProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    final birthdayItems = items.whereType<UserAgendaBirthdayItemEntity>();
    expect(birthdayItems, hasLength(1));
    expect(birthdayItems.single.id, 'birthday-person-maria-20260607');
    expect(birthdayItems.single.name, 'Maria');
    expect(birthdayItems.single.personId, 'person-maria');
    expect(birthdayItems.single.startDateTime, DateTime(2026, 6, 7));
    expect(items.map((item) => item.id), isNot(contains('demo-birthday-ana')));
    expect(
      items.map((item) => item.id),
      isNot(contains('demo-birthday-cecilia')),
    );
    expect(items.whereType<UserAgendaPersonalScaleItemEntity>(), isEmpty);
    expect(birthdayRequests, [
      UnitBirthdaysRequest(
        start: DateTime(2026, 5, 31),
        end: DateTime(2026, 7, 4),
      ),
    ]);
  });

  test('falha dos aniversariantes nao impede eventos reais', () async {
    birthdayFailure = const NetworkFailure('Falha em aniversariantes');
    visibleEvents = [
      _calendarEvent(
        id: 'real-event-1',
        title: 'Evento real',
        type: CalendarEventType.unit,
        unitId: 'unit-1',
        startDateTime: DateTime(2026, 6, 3, 19),
        endDateTime: DateTime(2026, 6, 3, 21),
      ),
    ];

    final items = await container.read(
      userAgendaItemsProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(items.map((item) => item.id), contains('real-event-1'));
    expect(items.whereType<UserAgendaBirthdayItemEntity>(), isEmpty);
    expect(items.whereType<UserAgendaPersonalScaleItemEntity>(), isEmpty);
  });

  test('falha dos eventos reais ainda gera erro global', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
        visibleCalendarEventsProvider.overrideWith(
          (ref, request) => Future<List<CalendarEventEntity>>.error(
            const NetworkFailure('Falha nos eventos'),
          ),
        ),
        unitBirthdaysProvider.overrideWith(
          (ref, request) async => const [
            PersonBirthdayEntity(
              id: 'person-maria',
              name: 'Maria',
              birthdayMonth: 6,
              birthdayDay: 7,
            ),
          ],
        ),
      ],
    );

    await expectLater(
      _readFutureProvider(
        container,
        userAgendaItemsProvider(
          UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
        ),
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('aniversariante fora do intervalo visivel nao entra na lista', () async {
    unitBirthdays = const [
      PersonBirthdayEntity(
        id: 'person-out',
        name: 'Fora',
        birthdayMonth: 8,
        birthdayDay: 10,
      ),
    ];

    final items = await container.read(
      userAgendaItemsProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(items.whereType<UserAgendaBirthdayItemEntity>(), isEmpty);
  });

  test(
    'aniversariante real cria marcador de aniversario no view model',
    () async {
      unitBirthdays = const [
        PersonBirthdayEntity(
          id: 'person-maria',
          name: 'Maria',
          birthdayMonth: 6,
          birthdayDay: 7,
        ),
      ];

      final state = await readState();

      expect(state.markersByDate[DateTime(2026, 6, 7)]?.hasBirthday, isTrue);
    },
  );

  test('fonte real sem aniversariantes nao inclui escala demo local', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
        visibleCalendarEventsProvider.overrideWith(
          (ref, request) async => const [],
        ),
        unitBirthdaysProvider.overrideWith((ref, request) async => const []),
      ],
    );

    final items = await container.read(
      userAgendaItemsProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(items.whereType<UserAgendaBirthdayItemEntity>(), isEmpty);
    expect(items.whereType<UserAgendaPersonalScaleItemEntity>(), isEmpty);
  });

  test('escala real aparece como mini card colado ao evento', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final request = UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6));
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
    ];

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: [
        _calendarEvent(
          id: 'event-1',
          title: 'Culto de domingo',
          type: CalendarEventType.department,
          departmentId: 'dep-1',
        ),
      ],
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
          ],
        ),
      ),
    );

    final items = await localContainer.read(
      userAgendaItemsProvider(request).future,
    );
    final event = items.whereType<UserAgendaEventItemEntity>().single;

    expect(event.personalScales, hasLength(1));
    expect(event.personalScales.single.department, 'Louvor');
    expect(event.personalScales.single.roles, ['Vocal']);
  });

  test('escala real sem evento visivel vira card proprio', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final request = UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6));
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
    ];

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: const [],
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
          ],
        ),
      ),
    );

    final items = await localContainer.read(
      userAgendaItemsProvider(request).future,
    );
    final standalone = items
        .whereType<UserAgendaPersonalScaleItemEntity>()
        .single;

    expect(standalone.scaleId, 'scale-1');
    expect(standalone.department, 'Louvor');
    expect(standalone.roles, ['Vocal']);
  });

  test('falha total de minhas escalas nao impede eventos reais', () async {
    final request = UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6));
    container.dispose();
    container = ProviderContainer(
      overrides: [
        userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
        visibleCalendarEventsProvider.overrideWith(
          (ref, request) async => [
            _calendarEvent(
              id: 'real-event-1',
              title: 'Evento real',
              type: CalendarEventType.unit,
              unitId: 'unit-1',
            ),
          ],
        ),
        unitBirthdaysProvider.overrideWith((ref, request) async => const []),
        myCalendarScalesProvider.overrideWith(
          (ref, request) =>
              Future<List<DepartmentCalendarEventScaleEntity>>.error(
                const NetworkFailure('Falha em minhas escalas'),
              ),
        ),
      ],
    );

    final items = await container.read(userAgendaItemsProvider(request).future);

    expect(
      items.whereType<UserAgendaEventItemEntity>().map((item) => item.id),
      ['real-event-1'],
    );
    expect(items.whereType<UserAgendaPersonalScaleItemEntity>(), isEmpty);
  });

  test('dia com escala real gera marcador hasUserScale', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: [
        _calendarEvent(
          id: 'event-1',
          title: 'Culto de domingo',
          type: CalendarEventType.department,
          departmentId: 'dep-1',
          startDateTime: DateTime(2026, 6, 7, 18),
          endDateTime: DateTime(2026, 6, 7, 20),
        ),
      ],
      myScales: [
        _personalScaleEvent(
          scaleId: 'scale-1',
          lineupId: 'lineup-1',
          eventId: 'event-1',
          departmentId: 'dep-1',
          title: 'Culto de domingo',
          startDateTime: DateTime(2026, 6, 7, 18),
          endDateTime: DateTime(2026, 6, 7, 20),
        ),
      ],
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
          ],
        ),
      ),
    );

    final state = await localContainer.read(userAgendaViewModelProvider.future);
    final marker = state.markersByDate[DateTime(2026, 6, 7)];

    expect(marker?.hasEvent, isTrue);
    expect(marker?.hasUserScale, isTrue);
  });

  test('Meus eventos inclui evento com personalScales', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: [
        _calendarEvent(
          id: 'event-1',
          title: 'Culto de domingo',
          type: CalendarEventType.department,
          departmentId: 'dep-1',
          startDateTime: DateTime(2026, 6, 3, 18),
          endDateTime: DateTime(2026, 6, 3, 20),
        ),
      ],
      myScales: [
        _personalScaleEvent(
          scaleId: 'scale-1',
          lineupId: 'lineup-1',
          eventId: 'event-1',
          departmentId: 'dep-1',
          title: 'Culto de domingo',
          startDateTime: DateTime(2026, 6, 3, 18),
          endDateTime: DateTime(2026, 6, 3, 20),
        ),
      ],
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
          ],
        ),
      ),
    );

    final state = await localContainer.read(userAgendaViewModelProvider.future);
    final userEvents = state.weeklyGroups
        .expand((group) => group.items)
        .where((item) => item.isUserEvent)
        .toList();

    expect(userEvents.map((item) => item.id), contains('event-1'));
    expect(userEvents.single, isA<UserAgendaEventItemEntity>());
  });

  test('Meus eventos inclui escala pessoal como item proprio', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: const [],
      myScales: [
        _personalScaleEvent(
          scaleId: 'scale-1',
          lineupId: 'lineup-1',
          eventId: 'event-1',
          departmentId: 'dep-1',
          title: 'Culto de domingo',
          startDateTime: DateTime(2026, 6, 3, 18),
          endDateTime: DateTime(2026, 6, 3, 20),
        ),
      ],
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
          ],
        ),
      ),
    );

    final state = await localContainer.read(userAgendaViewModelProvider.future);
    final userEvents = state.weeklyGroups
        .expand((group) => group.items)
        .where((item) => item.isUserEvent)
        .toList();

    expect(
      userEvents.map((item) => item.id),
      contains('personal-scale-scale-1'),
    );
    expect(userEvents.single, isA<UserAgendaPersonalScaleItemEntity>());
  });

  test('agrupa dois papeis do mesmo departamento em um mini card', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final visibleEvents = [
      _calendarEvent(
        id: 'event-1',
        title: 'Culto de domingo',
        type: CalendarEventType.department,
        departmentId: 'dep-1',
      ),
    ];
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
    ];

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
        ScaleItemEntity(
          id: 'item-2',
          scaleId: 'scale-1',
          roleId: 'role-violao',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
            _lineupItem(
              id: 'lineup-item-2',
              lineupId: 'lineup-1',
              roleId: 'role-violao',
              description: 'Violão',
              roleName: 'Violão',
            ),
          ],
        ),
      ),
    );

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: visibleEvents,
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    final result = await localContainer.read(
      userAgendaPersonalScalesProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(result.attachedScales, hasLength(1));
    expect(result.attachedScales.single.department, 'Louvor');
    expect(
      result.attachedScales.single.roles,
      containsAll(['Vocal', 'Violão']),
    );
  });

  test('cria um mini card por departamento no mesmo evento', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final visibleEvents = [
      _calendarEvent(
        id: 'event-1',
        title: 'Culto de domingo',
        type: CalendarEventType.department,
        departmentId: 'dep-1',
      ),
    ];
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
      _personalScaleEvent(
        scaleId: 'scale-2',
        lineupId: 'lineup-2',
        eventId: 'event-1',
        departmentId: 'dep-2',
        title: 'Culto de domingo',
      ),
    ];

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => calendarRepository.getScaleItems('scale-2')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-2',
          scaleId: 'scale-2',
          roleId: 'role-midias',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getDepartmentById('dep-2')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-2', name: 'Mídia')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
          ],
        ),
      ),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-2')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-2',
          name: 'Mídia',
          items: [
            _lineupItem(
              id: 'lineup-item-2',
              lineupId: 'lineup-2',
              roleId: 'role-midias',
              description: 'Câmeras',
              roleName: 'Câmeras',
            ),
          ],
        ),
      ),
    );

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: visibleEvents,
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    final result = await localContainer.read(
      userAgendaPersonalScalesProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(result.attachedScales, hasLength(2));
    expect(result.attachedScales.map((scale) => scale.department).toSet(), {
      'Louvor',
      'Mídia',
    });
  });

  test('deduplica papel repetido na mesma escala', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final visibleEvents = [
      _calendarEvent(
        id: 'event-1',
        title: 'Culto de domingo',
        type: CalendarEventType.department,
        departmentId: 'dep-1',
      ),
    ];
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
    ];

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
        ScaleItemEntity(
          id: 'item-2',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
          ],
        ),
      ),
    );

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: visibleEvents,
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    final result = await localContainer.read(
      userAgendaPersonalScalesProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(result.attachedScales, hasLength(1));
    expect(result.attachedScales.single.roles, ['Vocal']);
  });

  test('nao imprime funcao quando getScaleItems falha', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final visibleEvents = [
      _calendarEvent(
        id: 'event-1',
        title: 'Culto de domingo',
        type: CalendarEventType.department,
        departmentId: 'dep-1',
      ),
    ];
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
    ];

    when(
      () => calendarRepository.getScaleItems('scale-1'),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha na escala')));
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(lineupId: 'lineup-1', name: 'Louvor', items: const []),
      ),
    );

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: visibleEvents,
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    final result = await localContainer.read(
      userAgendaPersonalScalesProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(result.attachedScales, hasLength(1));
    expect(result.attachedScales.single.roles, isEmpty);
  });

  test('nao imprime funcao quando getLineupWithItems falha', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final visibleEvents = [
      _calendarEvent(
        id: 'event-1',
        title: 'Culto de domingo',
        type: CalendarEventType.department,
        departmentId: 'dep-1',
      ),
    ];
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
    ];

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(
      () => departmentRepository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha na formação')));

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: visibleEvents,
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    final result = await localContainer.read(
      userAgendaPersonalScalesProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(result.attachedScales, hasLength(1));
    expect(result.attachedScales.single.roles, isEmpty);
  });

  test('nao mostra escala sem item do usuario', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final visibleEvents = [
      _calendarEvent(
        id: 'event-1',
        title: 'Culto de domingo',
        type: CalendarEventType.department,
        departmentId: 'dep-1',
      ),
    ];
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
    ];

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'outra-pessoa',
        ),
      ]),
    );

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: visibleEvents,
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    final result = await localContainer.read(
      userAgendaPersonalScalesProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(result.attachedScales, isEmpty);
    expect(result.standaloneItems, isEmpty);
  });

  test('materializa card proprio quando o evento nao esta visivel', () async {
    final calendarRepository = _MockCalendarEventRepository();
    final departmentRepository = _MockDepartmentRepository();
    final visibleEvents = <CalendarEventEntity>[];
    final myScales = [
      _personalScaleEvent(
        scaleId: 'scale-1',
        lineupId: 'lineup-1',
        eventId: 'event-1',
        departmentId: 'dep-1',
        title: 'Culto de domingo',
      ),
    ];

    when(() => calendarRepository.getScaleItems('scale-1')).thenAnswer(
      (_) async => const Right([
        ScaleItemEntity(
          id: 'item-1',
          scaleId: 'scale-1',
          roleId: 'role-vocal',
          personId: 'person-1',
        ),
      ]),
    );
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async =>
          const Right(DepartmentDetailEntity(id: 'dep-1', name: 'Louvor')),
    );
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => Right(
        _lineupWithRoles(
          lineupId: 'lineup-1',
          name: 'Louvor',
          items: [
            _lineupItem(
              id: 'lineup-item-1',
              lineupId: 'lineup-1',
              roleId: 'role-vocal',
              description: 'Vocal',
              roleName: 'Vocal',
            ),
          ],
        ),
      ),
    );

    final localContainer = _buildPersonalScalesContainer(
      visibleEvents: visibleEvents,
      myScales: myScales,
      calendarEventRepository: calendarRepository,
      departmentRepository: departmentRepository,
    );
    addTearDown(localContainer.dispose);

    final result = await localContainer.read(
      userAgendaPersonalScalesProvider(
        UserAgendaItemsRequest.forFocusedMonth(DateTime(2026, 6)),
      ).future,
    );

    expect(result.attachedScales, isEmpty);
    expect(result.standaloneItems, hasLength(1));
    expect(result.standaloneItems.single.department, 'Louvor');
    expect(result.standaloneItems.single.roles, contains('Vocal'));
  });
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
