import 'package:client/core/media/media_providers.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/presentation/widgets/event_card.dart';
import 'package:client/features/calendar/presentation/widgets/event_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EventImage resolve imagem e usa BoxFit.contain', (tester) async {
    await tester.pumpWidget(
      _build(
        child: const EventImage(imageId: 'image-1'),
        resolveImageUrl: (_) async => 'https://example.com/event.png',
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.byKey(const Key('event-image-network')),
    );
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('EventCard renderiza imagem quando cardImageId existe', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        child: EventCard(event: _event(cardImageId: 'image-1')),
        resolveImageUrl: (_) async => 'https://example.com/event.png',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EventImage), findsOneWidget);
    expect(find.byKey(const Key('event-image-network')), findsOneWidget);
  });

  testWidgets(
    'EventCard renderiza fallback sem imagem quando cardImageId vazio',
    (tester) async {
      var resolveCount = 0;

      await tester.pumpWidget(
        _build(
          child: EventCard(event: _event(cardImageId: '')),
          resolveImageUrl: (_) async {
            resolveCount++;
            return 'https://example.com/event.png';
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EventImage), findsNothing);
      expect(resolveCount, 0);
      expect(find.text('Culto de Celebração'), findsOneWidget);
    },
  );
}

Widget _build({
  required Widget child,
  required Future<String> Function(String imageId) resolveImageUrl,
}) {
  return ProviderScope(
    overrides: [
      mediaImageUrlProvider.overrideWith(
        (ref, imageId) => resolveImageUrl(imageId),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
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
