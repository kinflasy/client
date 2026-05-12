import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/presentation/widgets/event_detail_bottom_sheet.dart';
import 'package:client/features/calendar/presentation/widgets/event_image.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarEventRepository extends Mock
    implements CalendarEventRepository {}

void main() {
  testWidgets('renderiza loading enquanto carrega o detalhe', (tester) async {
    final completer = Completer<CalendarEventEntity>();
    addTearDown(() {
      if (!completer.isCompleted) completer.complete(_event());
    });

    await tester.pumpWidget(_build(loadDetail: (_) => completer.future));

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Carregando detalhes do evento...'), findsOneWidget);
  });

  testWidgets('renderiza erro quando detalhe falha', (tester) async {
    await tester.pumpWidget(
      _build(loadDetail: (_) => Future.error(Exception('falha'))),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os detalhes do evento.'),
      findsOneWidget,
    );
    expect(find.text('Tente novamente em instantes.'), findsOneWidget);
  });

  testWidgets('renderiza detalhe do evento', (tester) async {
    await tester.pumpWidget(_build(loadDetail: (_) async => _event()));

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Culto de Celebração'), findsOneWidget);
    expect(find.text('10 mai 18:00 - 10 mai 20:00'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('Encontro aberto para toda a unidade.'), findsOneWidget);
    expect(find.text('Unidade'), findsOneWidget);
  });

  testWidgets('renderiza imagem no topo do detalhe quando existe cardImageId', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(cardImageId: 'image-1'),
        resolveImageUrl: (_) async => 'https://example.com/event.png',
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.byType(EventImage), findsOneWidget);
    expect(find.byKey(const Key('event-image-network')), findsOneWidget);
  });

  testWidgets('exige confirmação antes de excluir evento', (tester) async {
    final repository = _MockCalendarEventRepository();
    when(
      () => repository.deleteEvent('event-1'),
    ).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(),
        canAdmin: true,
        repository: repository,
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir evento'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir evento'), findsWidgets);
    expect(
      find.text('Tem certeza que deseja excluir este evento?'),
      findsOneWidget,
    );
    verifyNever(() => repository.deleteEvent('event-1'));

    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteEvent('event-1')).called(1);
    expect(find.text('Evento excluído.'), findsOneWidget);
  });

  testWidgets('não mostra ações de imagem no detalhe', (tester) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(cardImageId: 'image-1'),
        canAdmin: true,
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Editar evento'), findsOneWidget);
    expect(find.text('Excluir evento'), findsOneWidget);
    expect(find.text('Trocar imagem'), findsNothing);
    expect(find.text('Adicionar imagem'), findsNothing);
    expect(find.text('Remover imagem'), findsNothing);
  });
}

Widget _build({
  required Future<CalendarEventEntity> Function(String eventId) loadDetail,
  Future<String> Function(String imageId)? resolveImageUrl,
  bool canAdmin = false,
  CalendarEventRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      calendarEventDetailProvider.overrideWith(
        (ref, eventId) => loadDetail(eventId),
      ),
      mediaImageUrlProvider.overrideWith(
        (ref, imageId) async =>
            resolveImageUrl?.call(imageId) ??
            Future.value('https://example.com/event.png'),
      ),
      sessionPermissionsProvider.overrideWith(
        (ref) async => _permissions(isUnitAdmin: canAdmin),
      ),
      if (repository != null)
        calendarEventRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  showEventDetailBottomSheet(context, eventId: 'event-1'),
              child: const Text('Abrir detalhe'),
            ),
          ),
        ),
      ),
    ),
  );
}

SessionPermissions _permissions({required bool isUnitAdmin}) {
  return SessionPermissions(
    isAuthenticated: true,
    affiliation: Affiliation.member,
    activeUnitId: 'unit-1',
    hasMembership: true,
    integrations: const [],
    isUnitAdmin: isUnitAdmin,
  );
}

CalendarEventEntity _event({String? cardImageId}) {
  return CalendarEventEntity(
    id: 'event-1',
    title: 'Culto de Celebração',
    description: 'Encontro aberto para toda a unidade.',
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: CalendarEventType.unit,
    unitId: 'unit-1',
    cardImageId: cardImageId,
  );
}
