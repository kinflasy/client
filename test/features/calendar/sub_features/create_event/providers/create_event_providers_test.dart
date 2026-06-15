import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/providers/user_agenda_providers.dart';
import 'package:client/features/calendar/sub_features/create_event/providers/create_event_providers.dart';
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
  final subscription = container.listen<AsyncValue<T>>(
    provider,
    (_, _) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);

  return container.read(provider.future);
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

  test('cria evento de unidade sem imagem', () async {
    final event = _event(type: CalendarEventType.unit, unitId: 'unit-1');
    when(
      () => repository.createUnitEvent('unit-1', any()),
    ).thenAnswer((_) async => Right(event));

    final result = await container
        .read(createCalendarEventProvider.notifier)
        .createUnitEvent('unit-1', _request());

    expect(result, Right<Failure, CalendarEventEntity>(event));
    expect(container.read(createCalendarEventProvider).requireValue, event);
    verify(() => repository.createUnitEvent('unit-1', any())).called(1);
    verifyNever(() => repository.updateCardImage(any(), any()));
  });

  test('cria evento de departamento', () async {
    final event = _event(
      type: CalendarEventType.department,
      departmentId: 'dep-1',
    );
    when(
      () => repository.createDepartmentEvent('dep-1', any()),
    ).thenAnswer((_) async => Right(event));

    final result = await container
        .read(createCalendarEventProvider.notifier)
        .createDepartmentEvent('dep-1', _request());

    expect(result, Right<Failure, CalendarEventEntity>(event));
    verify(() => repository.createDepartmentEvent('dep-1', any())).called(1);
  });

  test('expõe falha de validação retornada pelo repository', () async {
    const failure = ValidationFailure('O fim deve ser posterior ao início.');
    when(
      () => repository.createUnitEvent('unit-1', any()),
    ).thenAnswer((_) async => const Left(failure));

    final result = await container
        .read(createCalendarEventProvider.notifier)
        .createUnitEvent('unit-1', _request());

    expect(result, const Left<Failure, CalendarEventEntity>(failure));
    expect(container.read(createCalendarEventProvider).hasError, isTrue);
  });

  test('faz upload da imagem depois de criar o evento', () async {
    final created = _event(type: CalendarEventType.unit, unitId: 'unit-1');
    final withImage = _event(
      type: CalendarEventType.unit,
      unitId: 'unit-1',
      cardImageId: 'media-1',
    );
    when(
      () => repository.createUnitEvent('unit-1', any()),
    ).thenAnswer((_) async => Right(created));
    when(
      () => repository.updateCardImage('event-1', '/tmp/card.png'),
    ).thenAnswer((_) async => Right(withImage));

    final result = await container
        .read(createCalendarEventProvider.notifier)
        .createUnitEvent('unit-1', _request(), cardImagePath: '/tmp/card.png');

    expect(result, Right<Failure, CalendarEventEntity>(withImage));
    verifyInOrder([
      () => repository.createUnitEvent('unit-1', any()),
      () => repository.updateCardImage('event-1', '/tmp/card.png'),
    ]);
  });

  test('recarrega agenda depois de criar evento de unidade', () async {
    final event = _event(type: CalendarEventType.unit, unitId: 'unit-1');
    when(
      () => repository.createUnitEvent('unit-1', any()),
    ).thenAnswer((_) async => Right(event));

    final agendaLoadCount = await _countAgendaReloadsAfter(
      container,
      repository,
      () => container
          .read(createCalendarEventProvider.notifier)
          .createUnitEvent('unit-1', _request()),
    );

    expect(agendaLoadCount, 2);
  });

  test('recarrega agenda depois de criar evento de departamento', () async {
    final event = _event(
      type: CalendarEventType.department,
      departmentId: 'dep-1',
    );
    when(
      () => repository.createDepartmentEvent('dep-1', any()),
    ).thenAnswer((_) async => Right(event));

    final agendaLoadCount = await _countAgendaReloadsAfter(
      container,
      repository,
      () => container
          .read(createCalendarEventProvider.notifier)
          .createDepartmentEvent('dep-1', _request()),
    );

    expect(agendaLoadCount, 2);
  });
}

Future<int> _countAgendaReloadsAfter(
  ProviderContainer container,
  CalendarEventRepository repository,
  Future<Object?> Function() action,
) async {
  final start = DateTime(2026, 5);
  final end = DateTime(2026, 6);
  final request = UserAgendaItemsRequest(start: start, end: end);
  var agendaLoadCount = 0;

  when(() => repository.getVisibleEvents(start, end)).thenAnswer((_) {
    agendaLoadCount++;
    return Future.value(
      Right([_event(type: CalendarEventType.unit, unitId: 'unit-1')]),
    );
  });

  await _readFutureProvider(container, userAgendaItemsProvider(request));
  await action();
  await container.read(userAgendaItemsProvider(request).future);

  return agendaLoadCount;
}

CalendarEventRequestModel _request() {
  return CalendarEventRequestModel(
    title: 'Culto especial',
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

CalendarEventEntity _event({
  required CalendarEventType type,
  String? unitId,
  String? departmentId,
  String? cardImageId,
}) {
  return CalendarEventEntity(
    id: 'event-1',
    title: 'Culto especial',
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: type,
    unitId: unitId,
    departmentId: departmentId,
    cardImageId: cardImageId,
  );
}
