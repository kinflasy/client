import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/event_collaboration_entity.dart';
import 'package:client/features/calendar/domain/entities/person_birthday_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

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

void main() {
  late _MockCalendarEventRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockCalendarEventRepository();
    container = ProviderContainer(
      overrides: [
        calendarEventRepositoryProvider.overrideWithValue(repository),
        departmentsProvider.overrideWith((ref, unitId) async => const []),
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
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('unit provider passes request interval to repository', () async {
    final start = DateTime(2026, 5);
    final end = DateTime(2026, 6);
    final event = _event(
      id: 'event-1',
      title: 'Evento',
      type: CalendarEventType.unit,
      unitId: 'unit-1',
    );
    when(
      () => repository.getUnitEvents('unit-1', start, end),
    ).thenAnswer((_) async => Right([event]));

    final result = await _readFutureProvider(
      container,
      unitCalendarEventsProvider(
        UnitCalendarEventsRequest(unitId: 'unit-1', start: start, end: end),
      ),
    );

    expect(result, [event]);
    verify(() => repository.getUnitEvents('unit-1', start, end)).called(1);
  });

  test('visible provider returns repository events in source order', () async {
    final start = DateTime(2026, 5);
    final end = DateTime(2026, 6);
    final events = [
      _event(
        id: 'event-2',
        title: 'Segundo',
        type: CalendarEventType.department,
        departmentId: 'dep-1',
      ),
      _event(
        id: 'event-1',
        title: 'Primeiro',
        type: CalendarEventType.unit,
        unitId: 'unit-1',
      ),
    ];
    when(
      () => repository.getVisibleEvents(start, end),
    ).thenAnswer((_) async => Right(events));

    final result = await _readFutureProvider(
      container,
      visibleCalendarEventsProvider(
        VisibleCalendarEventsRequest(start: start, end: end),
      ),
    );

    expect(result, events);
    verify(() => repository.getVisibleEvents(start, end)).called(1);
  });

  test('visible provider surfaces repository failure', () async {
    final start = DateTime(2026, 5);
    final end = DateTime(2026, 6);
    when(() => repository.getVisibleEvents(start, end)).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao carregar eventos')),
    );

    await expectLater(
      _readFutureProvider(
        container,
        visibleCalendarEventsProvider(
          VisibleCalendarEventsRequest(start: start, end: end),
        ),
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test(
    'unit birthdays provider reads repository and returns birthdays',
    () async {
      final start = DateTime(2026, 6);
      final end = DateTime(2026, 6, 30);
      const birthdays = [
        PersonBirthdayEntity(
          id: 'person-1',
          name: 'Maria',
          birthdayMonth: 6,
          birthdayDay: 7,
        ),
      ];
      when(
        () => repository.getUnitBirthdays(start, end),
      ).thenAnswer((_) async => const Right(birthdays));

      final result = await _readFutureProvider(
        container,
        unitBirthdaysProvider(UnitBirthdaysRequest(start: start, end: end)),
      );

      expect(result, birthdays);
      verify(() => repository.getUnitBirthdays(start, end)).called(1);
    },
  );

  test('unit birthdays provider surfaces repository failure', () async {
    final start = DateTime(2026, 6);
    final end = DateTime(2026, 6, 30);
    when(() => repository.getUnitBirthdays(start, end)).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao carregar aniversarios')),
    );

    await expectLater(
      _readFutureProvider(
        container,
        unitBirthdaysProvider(UnitBirthdaysRequest(start: start, end: end)),
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('my scales provider reads repository and returns scales', () async {
    final start = DateTime(2026, 6);
    final end = DateTime(2026, 6, 30);
    final scales = [
      DepartmentCalendarEventScaleEntity(
        scale: const CalendarEventScaleEntity(
          id: 'scale-1',
          lineupId: 'lineup-1',
          type: CalendarEventScaleType.owner,
          calendarEventId: 'event-1',
        ),
        calendarEvent: _event(
          id: 'event-1',
          title: 'Culto',
          type: CalendarEventType.department,
          departmentId: 'dep-1',
        ),
      ),
    ];
    when(
      () => repository.getMyScales(start, end),
    ).thenAnswer((_) async => Right(scales));

    final result = await _readFutureProvider(
      container,
      myCalendarScalesProvider(MyCalendarScalesRequest(start: start, end: end)),
    );

    expect(result, scales);
    verify(() => repository.getMyScales(start, end)).called(1);
  });

  test('my scales provider surfaces repository failure', () async {
    final start = DateTime(2026, 6);
    final end = DateTime(2026, 6, 30);
    when(() => repository.getMyScales(start, end)).thenAnswer(
      (_) async =>
          const Left(NetworkFailure('Falha ao carregar minhas escalas')),
    );

    await expectLater(
      _readFutureProvider(
        container,
        myCalendarScalesProvider(
          MyCalendarScalesRequest(start: start, end: end),
        ),
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('department provider surfaces repository failure', () async {
    final start = DateTime(2026, 5);
    final end = DateTime(2026, 6);
    when(() => repository.getDepartmentEvents('dep-1', start, end)).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao carregar eventos')),
    );

    await expectLater(
      _readFutureProvider(
        container,
        departmentCalendarEventsProvider(
          DepartmentCalendarEventsRequest(
            departmentId: 'dep-1',
            start: start,
            end: end,
          ),
        ),
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('manual invalidation reloads listing providers', () async {
    final start = DateTime(2026, 5);
    final end = DateTime(2026, 6);
    final request = UnitCalendarEventsRequest(
      unitId: 'unit-1',
      start: start,
      end: end,
    );
    var loadCount = 0;
    when(() => repository.getUnitEvents('unit-1', start, end)).thenAnswer((_) {
      loadCount++;
      return Future.value(const Right(<CalendarEventEntity>[]));
    });

    final subscription = container.listen(
      unitCalendarEventsProvider(request),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(unitCalendarEventsProvider(request).future);
    container.invalidate(unitCalendarEventsProvider(request));
    await container.read(unitCalendarEventsProvider(request).future);

    expect(loadCount, 2);
  });

  test('visible unit provider includes visible department events', () async {
    final start = DateTime(2026, 5);
    final end = DateTime(2026, 6);
    final request = UnitCalendarEventsRequest(
      unitId: 'unit-1',
      start: start,
      end: end,
    );
    final unitEvent = _event(
      id: 'event-1',
      title: 'Culto',
      type: CalendarEventType.unit,
      unitId: 'unit-1',
      startDateTime: DateTime(2026, 5, 12, 20),
    );
    final visibleDepartmentEvent = _event(
      id: 'event-2',
      title: 'Ensaio',
      type: CalendarEventType.department,
      departmentId: 'dep-1',
      startDateTime: DateTime(2026, 5, 10, 18),
      visibilityRules: const [
        VisibilityRuleEntity.department(
          departmentId: 'dep-1',
          integrationType: IntegrationType.integrant,
        ),
      ],
    );
    final hiddenDepartmentEvent = _event(
      id: 'event-3',
      title: 'Reunião da liderança',
      type: CalendarEventType.department,
      departmentId: 'dep-1',
      startDateTime: DateTime(2026, 5, 11, 18),
      visibilityRules: const [
        VisibilityRuleEntity.department(
          departmentId: 'dep-1',
          integrationType: IntegrationType.leader,
        ),
      ],
    );

    container.dispose();
    container = ProviderContainer(
      overrides: [
        calendarEventRepositoryProvider.overrideWithValue(repository),
        departmentsProvider.overrideWith(
          (ref, unitId) async => const [
            DepartmentEntity(id: 'dep-1', name: 'Louvor'),
          ],
        ),
        sessionPermissionsProvider.overrideWith(
          (ref) async => const SessionPermissions(
            isAuthenticated: true,
            affiliation: Affiliation.member,
            activeUnitId: 'unit-1',
            hasMembership: true,
            integrations: [
              IntegrationEntity(
                id: 'integration-1',
                membershipId: 'membership-1',
                departmentId: 'dep-1',
                departmentType: 'MINISTRY',
                integrationType: IntegrationType.integrant,
              ),
            ],
            isUnitAdmin: false,
          ),
        ),
      ],
    );

    when(
      () => repository.getUnitEvents('unit-1', start, end),
    ).thenAnswer((_) async => Right([unitEvent, visibleDepartmentEvent]));
    when(() => repository.getDepartmentEvents('dep-1', start, end)).thenAnswer(
      (_) async => Right([visibleDepartmentEvent, hiddenDepartmentEvent]),
    );

    final result = await _readFutureProvider(
      container,
      visibleUnitCalendarEventsProvider(request),
    );

    expect(result.map((event) => event.id), ['event-2', 'event-1']);
  });

  test('detail provider reads event by id', () async {
    final event = _event(
      id: 'event-1',
      title: 'Evento',
      type: CalendarEventType.department,
      departmentId: 'dep-1',
    );
    when(
      () => repository.getEventById('event-1'),
    ).thenAnswer((_) async => Right(event));

    final result = await _readFutureProvider(
      container,
      calendarEventDetailProvider('event-1'),
    );

    expect(result, event);
  });

  test('collaborators provider reads event collaborators by id', () async {
    const collaborators = [
      EventCollaborationEntity(
        id: 'collab-1',
        calendarEventId: 'event-1',
        departmentId: 'dep-1',
      ),
    ];
    when(
      () => repository.getCollaborators('event-1'),
    ).thenAnswer((_) async => const Right(collaborators));

    final result = await _readFutureProvider(
      container,
      calendarEventCollaboratorsProvider('event-1'),
    );

    expect(result, collaborators);
    verify(() => repository.getCollaborators('event-1')).called(1);
  });
}

CalendarEventEntity _event({
  required String id,
  required String title,
  required CalendarEventType type,
  String? unitId,
  String? departmentId,
  DateTime? startDateTime,
  List<VisibilityRuleEntity> visibilityRules = const [],
}) {
  return CalendarEventEntity(
    id: id,
    title: title,
    startDateTime: startDateTime ?? DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: type,
    unitId: unitId,
    departmentId: departmentId,
    visibilityRules: visibilityRules,
  );
}
