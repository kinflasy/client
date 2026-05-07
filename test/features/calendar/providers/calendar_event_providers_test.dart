import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
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
}

CalendarEventEntity _event({
  required String id,
  required String title,
  required CalendarEventType type,
  String? unitId,
  String? departmentId,
}) {
  return CalendarEventEntity(
    id: id,
    title: title,
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: type,
    unitId: unitId,
    departmentId: departmentId,
  );
}
