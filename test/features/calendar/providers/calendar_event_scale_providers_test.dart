import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/providers/calendar_event_scale_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarEventRepository extends Mock
    implements CalendarEventRepository {}

class _FakeCalendarEventScaleRequestModel extends Fake
    implements CalendarEventScaleRequestModel {}

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

  setUpAll(() {
    registerFallbackValue(_FakeCalendarEventScaleRequestModel());
  });

  setUp(() {
    repository = _MockCalendarEventRepository();
    container = ProviderContainer(
      overrides: [
        calendarEventRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('event scales provider returns list of scales', () async {
    when(
      () => repository.getEventScales('event-1'),
    ).thenAnswer((_) async => const Right([_ownerScale]));

    final result = await _readFutureProvider(
      container,
      eventScalesProvider('event-1'),
    );

    expect(result, const [_ownerScale]);
    verify(() => repository.getEventScales('event-1')).called(1);
  });

  test('create action sets loading and success states', () async {
    when(
      () => repository.createEventScale('event-1', any()),
    ).thenAnswer((_) async => const Right(_ownerScale));

    final states = <AsyncValue<void>>[];
    final subscription = container.listen(createEventScaleProvider, (
      previous,
      next,
    ) {
      states.add(next);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    final result = await container
        .read(createEventScaleProvider.notifier)
        .create(
          eventId: 'event-1',
          request: const CalendarEventScaleRequestModel(lineupId: 'lineup-1'),
        );

    expect(result.isRight(), isTrue);
    expect(states[0], const AsyncData<void>(null));
    expect(states[1].isLoading, isTrue);
    expect(states[2], const AsyncData<void>(null));
    verify(
      () => repository.createEventScale(
        'event-1',
        any(
          that: isA<CalendarEventScaleRequestModel>().having(
            (request) => request.lineupId,
            'lineupId',
            'lineup-1',
          ),
        ),
      ),
    ).called(1);
  });

  test('create action sets error state on failure', () async {
    const failure = ValidationFailure('Evento ja possui escala.');
    when(
      () => repository.createEventScale('event-1', any()),
    ).thenAnswer((_) async => const Left(failure));

    final result = await container
        .read(createEventScaleProvider.notifier)
        .create(
          eventId: 'event-1',
          request: const CalendarEventScaleRequestModel(lineupId: 'lineup-1'),
        );

    expect(result.isLeft(), isTrue);
    final state = container.read(createEventScaleProvider);
    expect(state.hasError, isTrue);
    expect(state.error, failure);
  });

  test('create action invalidates event scales after success', () async {
    var loadCount = 0;
    when(() => repository.getEventScales('event-1')).thenAnswer((_) {
      loadCount++;
      return Future.value(const Right(<CalendarEventScaleEntity>[]));
    });
    when(
      () => repository.createEventScale('event-1', any()),
    ).thenAnswer((_) async => const Right(_ownerScale));

    final subscription = container.listen(
      eventScalesProvider('event-1'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(eventScalesProvider('event-1').future);
    await container
        .read(createEventScaleProvider.notifier)
        .create(
          eventId: 'event-1',
          request: const CalendarEventScaleRequestModel(lineupId: 'lineup-1'),
        );
    await container.read(eventScalesProvider('event-1').future);

    expect(loadCount, 2);
  });

  test('eligible request helper builds interval from now to six months', () {
    final now = DateTime(2026, 5, 29, 10, 15, 30);

    final request = buildEligibleDepartmentScaleEventsRequest(
      'dep-1',
      now: now,
    );

    expect(request.departmentId, 'dep-1');
    expect(request.start, now);
    expect(request.end, DateTime(2026, 11, 29, 23, 59, 59));
  });

  test(
    'eligible provider calls department events with request interval',
    () async {
      final start = DateTime(2026, 5, 29, 10);
      final end = DateTime(2026, 11, 29, 23, 59, 59);
      final request = EligibleDepartmentScaleEventsRequest(
        departmentId: 'dep-1',
        start: start,
        end: end,
      );
      when(
        () => repository.getDepartmentEvents('dep-1', start, end),
      ).thenAnswer((_) async => const Right(<CalendarEventEntity>[]));

      final result = await _readFutureProvider(
        container,
        eligibleDepartmentScaleEventsProvider(request),
      );

      expect(result, isEmpty);
      verify(
        () => repository.getDepartmentEvents('dep-1', start, end),
      ).called(1);
    },
  );

  test('eligible provider removes past events and events with scale', () async {
    final start = DateTime(2026, 5, 29, 10);
    final end = DateTime(2026, 11, 29, 23, 59, 59);
    final past = _event(
      id: 'event-past',
      title: 'Evento passado',
      startDateTime: DateTime(2026, 5, 29, 9, 59),
    );
    final scaled = _event(
      id: 'event-scaled',
      title: 'Evento com escala',
      startDateTime: DateTime(2026, 5, 30, 10),
    );
    final eligible = _event(
      id: 'event-free',
      title: 'Evento sem escala',
      startDateTime: DateTime(2026, 5, 31, 10),
    );
    final request = EligibleDepartmentScaleEventsRequest(
      departmentId: 'dep-1',
      start: start,
      end: end,
    );

    when(
      () => repository.getDepartmentEvents('dep-1', start, end),
    ).thenAnswer((_) async => Right([past, scaled, eligible]));
    when(
      () => repository.getEventScales('event-scaled'),
    ).thenAnswer((_) async => const Right([_ownerScale]));
    when(
      () => repository.getEventScales('event-free'),
    ).thenAnswer((_) async => const Right(<CalendarEventScaleEntity>[]));

    final result = await _readFutureProvider(
      container,
      eligibleDepartmentScaleEventsProvider(request),
    );

    expect(result, [eligible]);
    verifyNever(() => repository.getEventScales('event-past'));
  });

  test('eligible provider keeps event at exact start instant', () async {
    final start = DateTime(2026, 5, 29, 10);
    final end = DateTime(2026, 11, 29, 23, 59, 59);
    final event = _event(
      id: 'event-now',
      title: 'Evento agora',
      startDateTime: start,
    );
    final request = EligibleDepartmentScaleEventsRequest(
      departmentId: 'dep-1',
      start: start,
      end: end,
    );

    when(
      () => repository.getDepartmentEvents('dep-1', start, end),
    ).thenAnswer((_) async => Right([event]));
    when(
      () => repository.getEventScales('event-now'),
    ).thenAnswer((_) async => const Right(<CalendarEventScaleEntity>[]));

    final result = await _readFutureProvider(
      container,
      eligibleDepartmentScaleEventsProvider(request),
    );

    expect(result, [event]);
  });

  test('eligible provider sorts by start date and title', () async {
    final start = DateTime(2026, 5, 29, 10);
    final end = DateTime(2026, 11, 29, 23, 59, 59);
    final later = _event(
      id: 'event-later',
      title: 'Culto',
      startDateTime: DateTime(2026, 6, 2, 10),
    );
    final sameStartB = _event(
      id: 'event-b',
      title: 'Vigília',
      startDateTime: DateTime(2026, 6),
    );
    final sameStartA = _event(
      id: 'event-a',
      title: 'Ensaio',
      startDateTime: DateTime(2026, 6),
    );
    final request = EligibleDepartmentScaleEventsRequest(
      departmentId: 'dep-1',
      start: start,
      end: end,
    );

    when(
      () => repository.getDepartmentEvents('dep-1', start, end),
    ).thenAnswer((_) async => Right([later, sameStartB, sameStartA]));
    for (final event in [later, sameStartB, sameStartA]) {
      when(
        () => repository.getEventScales(event.id),
      ).thenAnswer((_) async => const Right(<CalendarEventScaleEntity>[]));
    }

    final result = await _readFutureProvider(
      container,
      eligibleDepartmentScaleEventsProvider(request),
    );

    expect(result.map((event) => event.id), [
      'event-a',
      'event-b',
      'event-later',
    ]);
  });

  test('eligible provider propagates event scale query failure', () async {
    final start = DateTime(2026, 5, 29, 10);
    final end = DateTime(2026, 11, 29, 23, 59, 59);
    final event = _event(
      id: 'event-1',
      title: 'Evento',
      startDateTime: DateTime(2026, 6),
    );
    final request = EligibleDepartmentScaleEventsRequest(
      departmentId: 'dep-1',
      start: start,
      end: end,
    );

    when(
      () => repository.getDepartmentEvents('dep-1', start, end),
    ).thenAnswer((_) async => Right([event]));
    when(() => repository.getEventScales('event-1')).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao carregar escalas')),
    );

    await expectLater(
      _readFutureProvider(
        container,
        eligibleDepartmentScaleEventsProvider(request),
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });
}

const _ownerScale = CalendarEventScaleEntity(
  id: 'scale-1',
  lineupId: 'lineup-1',
  type: CalendarEventScaleType.owner,
  calendarEventId: 'event-1',
);

CalendarEventEntity _event({
  required String id,
  required String title,
  required DateTime startDateTime,
}) {
  return CalendarEventEntity(
    id: id,
    title: title,
    startDateTime: startDateTime,
    endDateTime: startDateTime.add(const Duration(hours: 2)),
    type: CalendarEventType.department,
    departmentId: 'dep-1',
  );
}
