import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarEventRepository extends Mock
    implements CalendarEventRepository {}

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _FakeCalendarEventScaleRequestModel extends Fake
    implements CalendarEventScaleRequestModel {}

class _FakeLineupItemRequestModel extends Fake
    implements LineupItemRequestModel {}

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

Future<List<T>> _readProviderValues<T>(
  ProviderContainer container,
  dynamic provider, {
  required int count,
}) async {
  final values = <T>[];
  final completer = Completer<List<T>>();
  final subscription = container.listen<AsyncValue<T>>(provider, (
    previous,
    next,
  ) {
    if (next.hasValue) {
      values.add(next.requireValue);
      if (values.length >= count && !completer.isCompleted) {
        completer.complete(values);
      }
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
  late _MockDepartmentRepository departmentRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(_FakeCalendarEventScaleRequestModel());
    registerFallbackValue(_FakeLineupItemRequestModel());
  });

  setUp(() {
    repository = _MockCalendarEventRepository();
    departmentRepository = _MockDepartmentRepository();
    container = ProviderContainer(
      overrides: [
        calendarEventRepositoryProvider.overrideWithValue(repository),
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
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
    'department scales request helper builds interval from now to six months',
    () {
      final now = DateTime(2026, 5, 29, 10, 15, 30);

      final request = buildDepartmentScalesRequest('dep-1', now: now);

      expect(request.departmentId, 'dep-1');
      expect(request.start, now);
      expect(request.end, DateTime(2026, 11, 29, 23, 59, 59));
    },
  );

  test(
    'department scales provider calls repository with request interval',
    () async {
      final start = DateTime(2026, 5, 29, 10);
      final end = DateTime(2026, 11, 29, 23, 59, 59);
      final request = DepartmentScalesRequest(
        departmentId: 'dep-1',
        start: start,
        end: end,
      );
      when(
        () => repository.getDepartmentScales('dep-1', start, end),
      ).thenAnswer(
        (_) async => const Right(<DepartmentCalendarEventScaleEntity>[]),
      );

      final result = await _readFutureProvider(
        container,
        departmentScalesProvider(request),
      );

      expect(result, isEmpty);
      verify(
        () => repository.getDepartmentScales('dep-1', start, end),
      ).called(1);
    },
  );

  test('department scales provider sorts by date title and scale id', () async {
    final start = DateTime(2026, 5, 29, 10);
    final end = DateTime(2026, 11, 29, 23, 59, 59);
    final request = DepartmentScalesRequest(
      departmentId: 'dep-1',
      start: start,
      end: end,
    );
    final later = _departmentScale(
      scaleId: 'scale-later',
      eventId: 'event-later',
      title: 'Culto',
      startDateTime: DateTime(2026, 6, 2, 10),
    );
    final sameStartB = _departmentScale(
      scaleId: 'scale-b',
      eventId: 'event-b',
      title: 'Vigília',
      startDateTime: DateTime(2026, 6),
    );
    final sameStartA = _departmentScale(
      scaleId: 'scale-a',
      eventId: 'event-a',
      title: 'Ensaio',
      startDateTime: DateTime(2026, 6),
    );
    final sameTitleLaterId = _departmentScale(
      scaleId: 'scale-2',
      eventId: 'event-same-2',
      title: 'Ceia',
      startDateTime: DateTime(2026, 5, 31),
    );
    final sameTitleEarlierId = _departmentScale(
      scaleId: 'scale-1',
      eventId: 'event-same-1',
      title: 'Ceia',
      startDateTime: DateTime(2026, 5, 31),
    );

    when(() => repository.getDepartmentScales('dep-1', start, end)).thenAnswer(
      (_) async => Right([
        later,
        sameStartB,
        sameStartA,
        sameTitleLaterId,
        sameTitleEarlierId,
      ]),
    );

    final result = await _readFutureProvider(
      container,
      departmentScalesProvider(request),
    );

    expect(result.map((scale) => scale.scale.id), [
      'scale-1',
      'scale-2',
      'scale-a',
      'scale-b',
      'scale-later',
    ]);
  });

  test('department scales provider propagates repository failure', () async {
    final start = DateTime(2026, 5, 29, 10);
    final end = DateTime(2026, 11, 29, 23, 59, 59);
    final request = DepartmentScalesRequest(
      departmentId: 'dep-1',
      start: start,
      end: end,
    );
    when(() => repository.getDepartmentScales('dep-1', start, end)).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao carregar escalas')),
    );

    await expectLater(
      _readFutureProvider(container, departmentScalesProvider(request)),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('department scales with lineups provider returns empty list', () async {
    final request = _departmentScalesRequest();
    when(
      () => repository.getDepartmentScales(
        request.departmentId,
        request.start,
        request.end,
      ),
    ).thenAnswer(
      (_) async => const Right(<DepartmentCalendarEventScaleEntity>[]),
    );

    final result = await _readFutureProvider(
      container,
      departmentScalesWithLineupsProvider(request),
    );

    expect(result, isEmpty);
    verifyNever(() => departmentRepository.getLineupWithItems(any()));
  });

  test(
    'department scales with lineups provider preserves scale and item order',
    () async {
      final request = _departmentScalesRequest();
      final first = _departmentScale(
        scaleId: 'scale-1',
        eventId: 'event-1',
        title: 'Ceia',
        startDateTime: DateTime(2026, 5, 31),
        lineupId: 'lineup-1',
      );
      final second = _departmentScale(
        scaleId: 'scale-2',
        eventId: 'event-2',
        title: 'Culto',
        startDateTime: DateTime(2026, 6, 7),
        lineupId: 'lineup-2',
      );
      const lineupOne = LineupEntity(
        id: 'lineup-1',
        name: 'Ceia',
        items: [
          LineupItemEntity(
            id: 'item-1',
            lineupId: 'lineup-1',
            roleId: 'role-1',
            description: 'Vocal',
          ),
          LineupItemEntity(
            id: 'item-2',
            lineupId: 'lineup-1',
            roleId: 'role-2',
            description: 'Violao',
          ),
        ],
      );
      const lineupTwo = LineupEntity(id: 'lineup-2', name: 'Culto');

      when(
        () => repository.getDepartmentScales(
          request.departmentId,
          request.start,
          request.end,
        ),
      ).thenAnswer((_) async => Right([second, first]));
      when(
        () => departmentRepository.getLineupWithItems('lineup-1'),
      ).thenAnswer((_) async => const Right(lineupOne));
      when(
        () => departmentRepository.getLineupWithItems('lineup-2'),
      ).thenAnswer((_) async => const Right(lineupTwo));

      final result = await _readFutureProvider(
        container,
        departmentScalesWithLineupsProvider(request),
      );

      expect(result.map((item) => item.scale.scale.id), ['scale-1', 'scale-2']);
      expect(result.map((item) => item.lineup?.id), ['lineup-1', 'lineup-2']);
      expect(result.first.lineup?.items?.map((item) => item.description), [
        'Vocal',
        'Violao',
      ]);
    },
  );

  test(
    'department scales with lineups provider deduplicates lineup id',
    () async {
      final request = _departmentScalesRequest();
      final first = _departmentScale(
        scaleId: 'scale-1',
        eventId: 'event-1',
        title: 'Ceia',
        startDateTime: DateTime(2026, 5, 31),
        lineupId: 'lineup-shared',
      );
      final second = _departmentScale(
        scaleId: 'scale-2',
        eventId: 'event-2',
        title: 'Culto',
        startDateTime: DateTime(2026, 6, 7),
        lineupId: 'lineup-shared',
      );
      const lineup = LineupEntity(id: 'lineup-shared', name: 'Louvor');

      when(
        () => repository.getDepartmentScales(
          request.departmentId,
          request.start,
          request.end,
        ),
      ).thenAnswer((_) async => Right([first, second]));
      when(
        () => departmentRepository.getLineupWithItems('lineup-shared'),
      ).thenAnswer((_) async => const Right(lineup));

      final result = await _readFutureProvider(
        container,
        departmentScalesWithLineupsProvider(request),
      );

      expect(result.map((item) => item.lineup), [lineup, lineup]);
      verify(
        () => departmentRepository.getLineupWithItems('lineup-shared'),
      ).called(1);
    },
  );

  test(
    'department scales with lineups provider keeps cards on partial failure',
    () async {
      final request = _departmentScalesRequest();
      final failedFirst = _departmentScale(
        scaleId: 'scale-1',
        eventId: 'event-1',
        title: 'Ceia',
        startDateTime: DateTime(2026, 5, 31),
        lineupId: 'lineup-failed',
      );
      final loaded = _departmentScale(
        scaleId: 'scale-2',
        eventId: 'event-2',
        title: 'Culto',
        startDateTime: DateTime(2026, 6, 7),
        lineupId: 'lineup-loaded',
      );
      final failedSecond = _departmentScale(
        scaleId: 'scale-3',
        eventId: 'event-3',
        title: 'Ensaio',
        startDateTime: DateTime(2026, 6, 8),
        lineupId: 'lineup-failed',
      );
      const lineup = LineupEntity(id: 'lineup-loaded', name: 'Culto');

      when(
        () => repository.getDepartmentScales(
          request.departmentId,
          request.start,
          request.end,
        ),
      ).thenAnswer((_) async => Right([failedFirst, loaded, failedSecond]));
      when(
        () => departmentRepository.getLineupWithItems('lineup-failed'),
      ).thenAnswer(
        (_) async => const Left(NetworkFailure('Falha ao carregar formacao')),
      );
      when(
        () => departmentRepository.getLineupWithItems('lineup-loaded'),
      ).thenAnswer((_) async => const Right(lineup));

      final result = await _readFutureProvider(
        container,
        departmentScalesWithLineupsProvider(request),
      );

      expect(result.map((item) => item.scale.scale.id), [
        'scale-1',
        'scale-2',
        'scale-3',
      ]);
      expect(result[0].hasLineupFailure, isTrue);
      expect(result[0].lineup, isNull);
      expect(result[1].lineupState, DepartmentScaleLineupLoadState.loaded);
      expect(result[1].lineup, lineup);
      expect(result[2].hasLineupFailure, isTrue);
      verify(
        () => departmentRepository.getLineupWithItems('lineup-failed'),
      ).called(1);
    },
  );

  test(
    'department scales with lineups provider propagates general scale failure',
    () async {
      final request = _departmentScalesRequest();
      when(
        () => repository.getDepartmentScales(
          request.departmentId,
          request.start,
          request.end,
        ),
      ).thenAnswer(
        (_) async => const Left(NetworkFailure('Falha ao carregar escalas')),
      );

      await expectLater(
        _readFutureProvider(
          container,
          departmentScalesWithLineupsProvider(request),
        ),
        throwsA(isA<NetworkFailure>()),
      );

      verifyNever(() => departmentRepository.getLineupWithItems(any()));
    },
  );

  test('department scale detail provider returns complete detail', () async {
    const lineup = LineupEntity(id: 'lineup-1', name: 'Louvor completo');

    when(
      () => repository.getScaleById('scale-1'),
    ).thenAnswer((_) async => const Right(_ownerScale));
    when(
      () => repository.getEventById('event-1'),
    ).thenAnswer((_) async => Right(_event(id: 'event-1')));
    when(
      () => departmentRepository.getLineupWithItems('lineup-1'),
    ).thenAnswer((_) async => const Right(lineup));

    final result = await _readFutureProvider(
      container,
      departmentScaleDetailProvider(
        const DepartmentScaleDetailRequest(
          departmentId: 'dep-1',
          scaleId: 'scale-1',
        ),
      ),
    );

    expect(result.scale.scale, _ownerScale);
    expect(result.scale.calendarEvent.id, 'event-1');
    expect(result.lineupState, DepartmentScaleLineupLoadState.loaded);
    expect(result.lineup, lineup);
  });

  test(
    'department scale detail provider emits initial scale and still fetches backend',
    () async {
      const initialLineup = LineupEntity(
        id: 'lineup-1',
        name: 'Formacao local',
      );
      const refreshedLineup = LineupEntity(
        id: 'lineup-2',
        name: 'Formacao atualizada',
      );
      final initialScale = DepartmentScaleWithLineupEntity(
        scale: _departmentScale(
          scaleId: 'scale-1',
          eventId: 'event-1',
          title: 'Evento local',
          startDateTime: DateTime(2026, 5, 31),
          lineupId: 'lineup-1',
        ),
        lineupState: DepartmentScaleLineupLoadState.loaded,
        lineup: initialLineup,
      );
      const refreshedScale = CalendarEventScaleEntity(
        id: 'scale-1',
        lineupId: 'lineup-2',
        type: CalendarEventScaleType.owner,
        calendarEventId: 'event-2',
      );

      when(
        () => repository.getScaleById('scale-1'),
      ).thenAnswer((_) async => const Right(refreshedScale));
      when(
        () => repository.getEventById('event-2'),
      ).thenAnswer((_) async => Right(_event(id: 'event-2')));
      when(
        () => departmentRepository.getLineupWithItems('lineup-2'),
      ).thenAnswer((_) async => const Right(refreshedLineup));

      final values = await _readProviderValues(
        container,
        departmentScaleDetailProvider(
          DepartmentScaleDetailRequest(
            departmentId: 'dep-1',
            scaleId: 'scale-1',
            initialScale: initialScale,
          ),
        ),
        count: 2,
      );

      expect(values.first, initialScale);
      expect(values.last.scale.scale, refreshedScale);
      expect(values.last.scale.calendarEvent.id, 'event-2');
      expect(values.last.lineup, refreshedLineup);
      verify(() => repository.getScaleById('scale-1')).called(1);
    },
  );

  test(
    'department scale detail provider keeps detail when lineup fails',
    () async {
      when(
        () => repository.getScaleById('scale-1'),
      ).thenAnswer((_) async => const Right(_ownerScale));
      when(
        () => repository.getEventById('event-1'),
      ).thenAnswer((_) async => Right(_event(id: 'event-1')));
      when(
        () => departmentRepository.getLineupWithItems('lineup-1'),
      ).thenAnswer(
        (_) async => const Left(NetworkFailure('Falha na formacao')),
      );

      final result = await _readFutureProvider(
        container,
        departmentScaleDetailProvider(
          const DepartmentScaleDetailRequest(
            departmentId: 'dep-1',
            scaleId: 'scale-1',
          ),
        ),
      );

      expect(result.scale.scale, _ownerScale);
      expect(result.scale.calendarEvent.id, 'event-1');
      expect(result.lineupState, DepartmentScaleLineupLoadState.failed);
      expect(result.lineup, isNull);
    },
  );

  test(
    'department scale detail provider fails when scale fetch fails',
    () async {
      when(() => repository.getScaleById('scale-1')).thenAnswer(
        (_) async => const Left(NetworkFailure('Falha ao carregar escala')),
      );

      await expectLater(
        _readFutureProvider(
          container,
          departmentScaleDetailProvider(
            const DepartmentScaleDetailRequest(
              departmentId: 'dep-1',
              scaleId: 'scale-1',
            ),
          ),
        ),
        throwsA(isA<NetworkFailure>()),
      );

      verifyNever(() => repository.getEventById(any()));
      verifyNever(() => departmentRepository.getLineupWithItems(any()));
    },
  );

  test(
    'department scale detail provider fails with friendly message when event cannot be resolved',
    () async {
      const collaboratorScale = CalendarEventScaleEntity(
        id: 'scale-1',
        lineupId: 'lineup-1',
        type: CalendarEventScaleType.collaborator,
        collaborationId: 'collab-1',
      );
      when(
        () => repository.getScaleById('scale-1'),
      ).thenAnswer((_) async => const Right(collaboratorScale));

      await expectLater(
        _readFutureProvider(
          container,
          departmentScaleDetailProvider(
            const DepartmentScaleDetailRequest(
              departmentId: 'dep-1',
              scaleId: 'scale-1',
            ),
          ),
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.message,
            'message',
            'Não foi possível resolver o evento desta escala.',
          ),
        ),
      );

      verifyNever(() => repository.getEventById(any()));
      verifyNever(() => departmentRepository.getLineupWithItems(any()));
    },
  );

  test('create action invalidates department scales after success', () async {
    final request = buildDepartmentScalesRequest(
      'dep-1',
      now: DateTime(2026, 5, 29, 10),
    );
    var loadCount = 0;

    when(
      () => repository.getDepartmentScales('dep-1', request.start, request.end),
    ).thenAnswer((_) {
      loadCount++;
      return Future.value(const Right(<DepartmentCalendarEventScaleEntity>[]));
    });
    when(
      () => repository.createEventScale('event-1', any()),
    ).thenAnswer((_) async => const Right(_ownerScale));

    final subscription = container.listen(
      departmentScalesProvider(request),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(departmentScalesProvider(request).future);
    await container
        .read(createEventScaleProvider.notifier)
        .create(
          eventId: 'event-1',
          request: const CalendarEventScaleRequestModel(lineupId: 'lineup-1'),
        );
    await container.read(departmentScalesProvider(request).future);

    expect(loadCount, 2);
  });

  test(
    'create action invalidates department scales with lineups after success',
    () async {
      final request = _departmentScalesRequest();
      var loadCount = 0;
      final scale = _departmentScale(
        scaleId: 'scale-1',
        eventId: 'event-1',
        title: 'Ceia',
        startDateTime: DateTime(2026, 5, 31),
        lineupId: 'lineup-1',
      );

      when(
        () => repository.getDepartmentScales(
          request.departmentId,
          request.start,
          request.end,
        ),
      ).thenAnswer((_) {
        loadCount++;
        return Future.value(Right([scale]));
      });
      when(
        () => departmentRepository.getLineupWithItems('lineup-1'),
      ).thenAnswer(
        (_) async => const Right(LineupEntity(id: 'lineup-1', name: 'Ceia')),
      );
      when(
        () => repository.createEventScale('event-1', any()),
      ).thenAnswer((_) async => const Right(_ownerScale));

      final subscription = container.listen(
        departmentScalesWithLineupsProvider(request),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(departmentScalesWithLineupsProvider(request).future);
      await container
          .read(createEventScaleProvider.notifier)
          .create(
            eventId: 'event-1',
            request: const CalendarEventScaleRequestModel(lineupId: 'lineup-1'),
          );
      await container.read(departmentScalesWithLineupsProvider(request).future);

      expect(loadCount, 2);
    },
  );

  test(
    'lineup item changes invalidate lineup detail used by enriched scales',
    () async {
      final request = _departmentScalesRequest();
      var lineupLoadCount = 0;
      final scale = _departmentScale(
        scaleId: 'scale-1',
        eventId: 'event-1',
        title: 'Ceia',
        startDateTime: DateTime(2026, 5, 31),
        lineupId: 'lineup-1',
      );

      when(
        () => repository.getDepartmentScales(
          request.departmentId,
          request.start,
          request.end,
        ),
      ).thenAnswer((_) async => Right([scale]));
      when(
        () => departmentRepository.getLineupWithItems('lineup-1'),
      ).thenAnswer((_) {
        lineupLoadCount++;
        return Future.value(
          Right(
            LineupEntity(
              id: 'lineup-1',
              name: 'Ceia $lineupLoadCount',
              items: [
                LineupItemEntity(
                  id: 'item-$lineupLoadCount',
                  lineupId: 'lineup-1',
                  roleId: 'role-1',
                  description: 'Funcao $lineupLoadCount',
                ),
              ],
            ),
          ),
        );
      });
      when(
        () => departmentRepository.createLineupItem('lineup-1', any()),
      ).thenAnswer(
        (_) async => const Right(
          LineupItemEntity(
            id: 'item-new',
            lineupId: 'lineup-1',
            roleId: 'role-1',
            description: 'Nova funcao',
          ),
        ),
      );

      final subscription = container.listen(
        departmentScalesWithLineupsProvider(request),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final first = await container.read(
        departmentScalesWithLineupsProvider(request).future,
      );
      await container
          .read(lineupItemActionsProvider.notifier)
          .create(
            lineupId: 'lineup-1',
            departmentId: 'dep-1',
            request: const LineupItemRequestModel(
              roleId: 'role-1',
              description: 'Nova funcao',
            ),
          );
      final second = await container.read(
        departmentScalesWithLineupsProvider(request).future,
      );

      expect(first.single.lineup?.name, 'Ceia 1');
      expect(second.single.lineup?.name, 'Ceia 2');
    },
  );

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
  String title = 'Evento',
  DateTime? startDateTime,
}) {
  final start = startDateTime ?? DateTime(2026, 6);
  return CalendarEventEntity(
    id: id,
    title: title,
    startDateTime: start,
    endDateTime: start.add(const Duration(hours: 2)),
    type: CalendarEventType.department,
    departmentId: 'dep-1',
  );
}

DepartmentCalendarEventScaleEntity _departmentScale({
  required String scaleId,
  required String eventId,
  required String title,
  required DateTime startDateTime,
  String lineupId = 'lineup-1',
}) {
  return DepartmentCalendarEventScaleEntity(
    scale: CalendarEventScaleEntity(
      id: scaleId,
      lineupId: lineupId,
      type: CalendarEventScaleType.owner,
      calendarEventId: eventId,
    ),
    calendarEvent: _event(
      id: eventId,
      title: title,
      startDateTime: startDateTime,
    ),
  );
}

DepartmentScalesRequest _departmentScalesRequest() {
  return DepartmentScalesRequest(
    departmentId: 'dep-1',
    start: DateTime(2026, 5, 29, 10),
    end: DateTime(2026, 11, 29, 23, 59, 59),
  );
}
