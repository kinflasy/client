import 'dart:async';

import 'package:client/core/media/media_providers.dart';
import 'package:client/features/church/presentation/widgets/church_unit_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('avatar keeps initials while signed URL is loading', (
    tester,
  ) async {
    final completer = Completer<String>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaImageUrlProvider.overrideWith(
            (ref, imageId) => completer.future,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ChurchUnitAvatar(
              displayName: 'Sede Central',
              radius: 24,
              imageId: 'image-1',
            ),
          ),
        ),
      ),
    );

    expect(find.text('SC'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('avatar renders network image after signed URL is resolved', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaImageUrlProvider.overrideWith(
            (ref, imageId) async => 'https://cdn.example/$imageId.png',
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ChurchUnitAvatar(
              displayName: 'Sede Central',
              radius: 24,
              imageId: 'image-1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SC'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('cover falls back when signed URL resolution fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaImageUrlProvider.overrideWith(
            (ref, imageId) => Future<String>.error(Exception('failed')),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ChurchUnitCover(height: 120, imageId: 'image-1'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}
