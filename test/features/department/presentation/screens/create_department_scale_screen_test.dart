import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/presentation/screens/create_department_scale_screen.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarEventRepository extends Mock
    implements CalendarEventRepository {}

class _FakeCalendarEventScaleRequestModel extends Fake
    implements CalendarEventScaleRequestModel {}

void main() {
  late _MockCalendarEventRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeCalendarEventScaleRequestModel());
  });

  setUp(() {
    repository = _MockCalendarEventRepository();
  });

  testWidgets('shows loading while sources load', (tester) async {
    final completer = Completer<List<CalendarEventEntity>>();

    await _pumpScreen(
      tester,
      eventBuilder: (ref, request) => completer.future,
      lineups: const [],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows event source error', (tester) async {
    await _pumpScreen(
      tester,
      eventBuilder: (ref, request) =>
          Future.error(const NetworkFailure('Falha nos eventos')),
      lineups: const [],
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os eventos.'),
      findsOneWidget,
    );
    expect(find.text('Falha nos eventos'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no eligible events', (
    tester,
  ) async {
    await _pumpScreen(tester, events: const [], lineups: const [_lineup]);
    await tester.pumpAndSettle();

    expect(find.text('Nenhum evento disponível.'), findsOneWidget);
    expect(
      find.text(
        'Crie um evento futuro ou verifique se os eventos existentes já possuem escala.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows empty lineups state with navigation button', (
    tester,
  ) async {
    final router = _router(
      eventBuilder: (ref, request) async => [_event],
      lineups: const [],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    router.push('/departamentos/dep-1/escalas/nova');
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma formação cadastrada.'), findsOneWidget);
    expect(find.text('Criar formação'), findsOneWidget);

    await tester.tap(find.text('Criar formação'));
    await tester.pumpAndSettle();

    expect(find.text('Destino de formação'), findsOneWidget);
  });

  testWidgets('creates scale with selected event and lineup', (tester) async {
    when(
      () => repository.createEventScale('event-1', any()),
    ).thenAnswer((_) async => const Right(_scale));

    await _pumpScreen(
      tester,
      repository: repository,
      events: [_event],
      lineups: const [_lineup],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Culto da manhã').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Louvor completo').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar escala'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

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
    expect(find.text('Escala criada com sucesso.'), findsOneWidget);
  });

  testWidgets('shows creation failure message', (tester) async {
    when(() => repository.createEventScale('event-1', any())).thenAnswer(
      (_) async => const Left(ValidationFailure('Evento já possui escala.')),
    );

    await _pumpScreen(
      tester,
      repository: repository,
      events: [_event],
      lineups: const [_lineup],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Culto da manhã').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Louvor completo').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar escala'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Evento já possui escala.'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  _MockCalendarEventRepository? repository,
  List<CalendarEventEntity>? events,
  List<LineupEntity>? lineups,
  Future<List<CalendarEventEntity>> Function(
    Ref ref,
    EligibleDepartmentScaleEventsRequest request,
  )?
  eventBuilder,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          calendarEventRepositoryProvider.overrideWithValue(repository),
        eligibleDepartmentScaleEventsProvider.overrideWith(
          eventBuilder ?? (ref, request) async => events ?? const [],
        ),
        departmentLineupsProvider(
          'dep-1',
        ).overrideWith((ref) async => lineups ?? const []),
      ],
      child: const MaterialApp(
        home: CreateDepartmentScaleScreen(departmentId: 'dep-1'),
      ),
    ),
  );
}

GoRouter _router({
  _MockCalendarEventRepository? repository,
  required Future<List<CalendarEventEntity>> Function(
    Ref ref,
    EligibleDepartmentScaleEventsRequest request,
  )
  eventBuilder,
  required List<LineupEntity> lineups,
}) {
  return GoRouter(
    initialLocation: '/origem',
    routes: [
      GoRoute(
        path: '/origem',
        builder: (context, state) => const Scaffold(body: Text('Origem')),
      ),
      GoRoute(
        path: AppRoutes.departmentScaleCreate,
        name: AppRoutes.departmentScaleCreateName,
        builder: (context, state) => ProviderScope(
          overrides: [
            if (repository != null)
              calendarEventRepositoryProvider.overrideWithValue(repository),
            eligibleDepartmentScaleEventsProvider.overrideWith(eventBuilder),
            departmentLineupsProvider(
              state.pathParameters['id']!,
            ).overrideWith((ref) async => lineups),
          ],
          child: CreateDepartmentScaleScreen(
            departmentId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.departmentScaleFormationCreate,
        name: AppRoutes.departmentScaleFormationCreateName,
        builder: (context, state) =>
            const Scaffold(body: Text('Destino de formação')),
      ),
    ],
  );
}

final _event = CalendarEventEntity(
  id: 'event-1',
  title: 'Culto da manhã',
  startDateTime: DateTime(2026, 7, 20, 9),
  endDateTime: DateTime(2026, 7, 20, 11),
  type: CalendarEventType.department,
  departmentId: 'dep-1',
);

const _lineup = LineupEntity(id: 'lineup-1', name: 'Louvor completo');

const _scale = CalendarEventScaleEntity(
  id: 'scale-1',
  lineupId: 'lineup-1',
  type: CalendarEventScaleType.owner,
  calendarEventId: 'event-1',
);
