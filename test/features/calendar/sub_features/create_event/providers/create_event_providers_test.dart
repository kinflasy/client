import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/sub_features/create_event/providers/create_event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarEventRepository extends Mock
    implements CalendarEventRepository {}

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
