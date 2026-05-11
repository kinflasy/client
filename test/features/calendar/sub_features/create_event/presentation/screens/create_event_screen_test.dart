import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/sub_features/create_event/presentation/screens/create_event_screen.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  Widget buildApp({_CapturingCalendarEventRepository? repository}) {
    return ProviderScope(
      overrides: [
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        departmentsProvider('unit-1').overrideWith(
          (ref) async => const [DepartmentEntity(id: 'dep-1', name: 'Louvor')],
        ),
        if (repository != null)
          calendarEventRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: CreateEventScreen()),
    );
  }

  testWidgets('valida campos obrigatórios', (tester) async {
    await _pumpApp(tester, buildApp());

    expect(find.text('Organizado por *'), findsOneWidget);
    expect(find.text('Evento de *'), findsNothing);

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('Campo obrigatório'), findsNWidgets(5));
    expect(
      find.text('Adicione pelo menos uma regra de visibilidade.'),
      findsNothing,
    );
  });

  testWidgets('valida fim anterior ao início', (tester) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'Ensaio geral');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '20:00');
    await tester.enterText(_field('end-date-field'), '10/05/2026');
    await tester.enterText(_field('end-time-field'), '18:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('O fim deve ser posterior ao início.'), findsOneWidget);
  });

  testWidgets('autopreenche data e hora de fim a partir do início', (
    tester,
  ) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.pump();

    expect(_fieldText(tester, 'end-date-field'), '10/05/2026');
    expect(_fieldText(tester, 'end-time-field'), '20:00');
  });

  testWidgets('autopreenchimento ajusta data de fim na virada de dia', (
    tester,
  ) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '23:30');
    await tester.pump();

    expect(_fieldText(tester, 'end-date-field'), '11/05/2026');
    expect(_fieldText(tester, 'end-time-field'), '01:30');
  });

  testWidgets('autopreenchimento não sobrescreve fim manual', (tester) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(_field('end-date-field'), '12/05/2026');
    await tester.enterText(_field('end-time-field'), '21:00');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.pump();

    expect(_fieldText(tester, 'end-date-field'), '12/05/2026');
    expect(_fieldText(tester, 'end-time-field'), '21:00');
  });

  testWidgets('salvar sem regra específica envia USER *', (tester) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(tester, buildApp(repository: repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ensaio geral');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.enterText(_field('end-date-field'), '10/05/2026');
    await tester.enterText(_field('end-time-field'), '20:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.createdUnitEventRequest, isNotNull);
    expect(repository.createdUnitEventRequest!.visibilityRules, const [
      VisibilityRuleEntity.user(userId: '*'),
    ]);
    expect(
      find.text('Adicione pelo menos uma regra de visibilidade.'),
      findsNothing,
    );
  });
}

Future<void> _pumpApp(WidgetTester tester, Widget app) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Finder _field(String key) {
  return find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextFormField),
  );
}

String _fieldText(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(_field(key)).controller!.text;
}

CurrentChurchProfileEntity _profile() {
  return const CurrentChurchProfileEntity(
    membership: MembershipEntity(
      id: 'membership-1',
      unitId: 'unit-1',
      affiliation: 'UNIT_ADMIN',
    ),
    unit: ChurchUnitEntity(id: 'unit-1', churchId: 'church-1'),
    church: ChurchEntity(
      id: 'church-1',
      name: 'Igreja Pontis',
      slug: 'igreja-pontis',
      email: 'contato@pontis.test',
    ),
  );
}

class _CapturingCalendarEventRepository implements CalendarEventRepository {
  CalendarEventRequestModel? createdUnitEventRequest;

  @override
  Future<Either<Failure, CalendarEventEntity>> createUnitEvent(
    String unitId,
    CalendarEventRequestModel request,
  ) async {
    createdUnitEventRequest = request;
    return const Left(ServerFailure('Falha simulada.'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> createDepartmentEvent(
    String departmentId,
    CalendarEventRequestModel request,
  ) async {
    return const Left(ServerFailure('Falha simulada.'));
  }

  @override
  Future<Either<Failure, void>> deleteCardImage(String eventId) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String eventId) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> getEventById(
    String eventId,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<CalendarEventEntity>>> getDepartmentEvents(
    String departmentId,
    DateTime start,
    DateTime end,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<CalendarEventEntity>>> getUnitEvents(
    String unitId,
    DateTime start,
    DateTime end,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> updateCardImage(
    String eventId,
    String filePath,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> updateEvent(
    String eventId,
    CalendarEventRequestModel request,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }
}
