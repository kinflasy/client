import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/event_collaboration_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_actions_provider.dart';
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

  setUpAll(() {
    registerFallbackValue(_request());
  });

  setUp(() {
    repository = _MockCalendarEventRepository();
    container = ProviderContainer(
      overrides: [
        calendarEventRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('edita evento com sucesso', () async {
    final updated = _event(title: 'Evento atualizado');
    when(
      () => repository.updateEvent('event-1', any()),
    ).thenAnswer((_) async => Right(updated));

    final result = await container
        .read(calendarEventActionsProvider.notifier)
        .updateEvent('event-1', _request(title: 'Evento atualizado'));

    expect(result, Right<Failure, CalendarEventEntity>(updated));
    expect(container.read(calendarEventActionsProvider).hasValue, isTrue);
    verify(() => repository.updateEvent('event-1', any())).called(1);
  });

  test('expõe falha de edição', () async {
    const failure = ValidationFailure('O fim deve ser posterior ao início.');
    when(
      () => repository.updateEvent('event-1', any()),
    ).thenAnswer((_) async => const Left(failure));

    final result = await container
        .read(calendarEventActionsProvider.notifier)
        .updateEvent('event-1', _request());

    expect(result, const Left<Failure, CalendarEventEntity>(failure));
    expect(container.read(calendarEventActionsProvider).hasError, isTrue);
  });

  test('invalida detalhe depois de editar', () async {
    var detailLoadCount = 0;
    when(() => repository.getEventById('event-1')).thenAnswer((_) {
      detailLoadCount++;
      return Future.value(Right(_event(title: 'Evento $detailLoadCount')));
    });
    when(
      () => repository.updateEvent('event-1', any()),
    ).thenAnswer((_) async => Right(_event(title: 'Evento atualizado')));

    final subscription = container.listen(
      calendarEventDetailProvider('event-1'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _readFutureProvider(
      container,
      calendarEventDetailProvider('event-1'),
    );

    await container
        .read(calendarEventActionsProvider.notifier)
        .updateEvent('event-1', _request());

    await container.read(calendarEventDetailProvider('event-1').future);

    expect(detailLoadCount, 2);
  });

  test('atualiza imagem do card com sucesso', () async {
    final updated = _event(title: 'Evento com imagem');
    when(
      () => repository.updateCardImage('event-1', '/tmp/card.png'),
    ).thenAnswer((_) async => Right(updated));

    final result = await container
        .read(calendarEventActionsProvider.notifier)
        .updateCardImage('event-1', '/tmp/card.png');

    expect(result, Right<Failure, CalendarEventEntity>(updated));
    expect(container.read(calendarEventActionsProvider).hasValue, isTrue);
    verify(
      () => repository.updateCardImage('event-1', '/tmp/card.png'),
    ).called(1);
  });

  test('remove imagem do card com sucesso', () async {
    when(
      () => repository.deleteCardImage('event-1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await container
        .read(calendarEventActionsProvider.notifier)
        .deleteCardImage('event-1');

    expect(result, const Right<Failure, void>(null));
    expect(container.read(calendarEventActionsProvider).hasValue, isTrue);
    verify(() => repository.deleteCardImage('event-1')).called(1);
  });

  test('exclui evento com sucesso', () async {
    when(
      () => repository.deleteEvent('event-1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await container
        .read(calendarEventActionsProvider.notifier)
        .deleteEvent('event-1');

    expect(result, const Right<Failure, void>(null));
    expect(container.read(calendarEventActionsProvider).hasValue, isTrue);
    verify(() => repository.deleteEvent('event-1')).called(1);
  });

  test('sincroniza colaboradores adicionando e removendo diferenças', () async {
    when(
      () => repository.removeCollaborator('event-1', 'dep-old'),
    ).thenAnswer((_) async => const Right(null));
    when(() => repository.addCollaborator('event-1', 'dep-new')).thenAnswer(
      (_) async => const Right(
        EventCollaborationEntity(
          id: 'collab-new',
          calendarEventId: 'event-1',
          departmentId: 'dep-new',
        ),
      ),
    );

    final result = await container
        .read(calendarEventActionsProvider.notifier)
        .syncCollaborators(
          'event-1',
          originalDepartmentIds: {'dep-old', 'dep-kept'},
          selectedDepartmentIds: {'dep-kept', 'dep-new'},
        );

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.removeCollaborator('event-1', 'dep-old')).called(1);
    verify(() => repository.addCollaborator('event-1', 'dep-new')).called(1);
  });

  test('invalida detalhe e listagens depois de atualizar imagem', () async {
    final start = DateTime(2026, 5);
    final end = DateTime(2026, 6);
    final request = UnitCalendarEventsRequest(
      unitId: 'unit-1',
      start: start,
      end: end,
    );
    var detailLoadCount = 0;
    var listLoadCount = 0;
    when(() => repository.getEventById('event-1')).thenAnswer((_) {
      detailLoadCount++;
      return Future.value(Right(_event(title: 'Detalhe $detailLoadCount')));
    });
    when(() => repository.getUnitEvents('unit-1', start, end)).thenAnswer((_) {
      listLoadCount++;
      return Future.value(Right([_event(title: 'Lista $listLoadCount')]));
    });
    when(
      () => repository.updateCardImage('event-1', '/tmp/card.png'),
    ).thenAnswer((_) async => Right(_event(title: 'Atualizado')));

    final detailSubscription = container.listen(
      calendarEventDetailProvider('event-1'),
      (_, _) {},
      fireImmediately: true,
    );
    final listSubscription = container.listen(
      unitCalendarEventsProvider(request),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(detailSubscription.close);
    addTearDown(listSubscription.close);

    await _readFutureProvider(
      container,
      calendarEventDetailProvider('event-1'),
    );
    await _readFutureProvider(container, unitCalendarEventsProvider(request));

    await container
        .read(calendarEventActionsProvider.notifier)
        .updateCardImage('event-1', '/tmp/card.png');

    await container.read(calendarEventDetailProvider('event-1').future);
    await container.read(unitCalendarEventsProvider(request).future);

    expect(detailLoadCount, 2);
    expect(listLoadCount, 2);
  });
}

CalendarEventRequestModel _request({String title = 'Evento'}) {
  return CalendarEventRequestModel(
    title: title,
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    visibilityRules: const [
      VisibilityRuleEntity.unit(
        unitId: 'unit-1',
        affiliation: Affiliation.visitor,
      ),
    ],
  );
}

CalendarEventEntity _event({String title = 'Evento'}) {
  return CalendarEventEntity(
    id: 'event-1',
    title: title,
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: CalendarEventType.unit,
    unitId: 'unit-1',
  );
}
