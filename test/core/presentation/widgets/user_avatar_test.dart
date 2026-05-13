import 'dart:async';

import 'package:client/core/media/media_providers.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra iniciais enquanto a URL da imagem carrega', (
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
            body: UserAvatar(
              displayName: 'Lisa Silva',
              radius: 24,
              profileImageId: 'image-1',
            ),
          ),
        ),
      ),
    );

    expect(find.text('LS'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('mostra iniciais quando a URL da imagem falha', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaImageUrlProvider.overrideWith(
            (ref, imageId) => Future<String>.error(Exception('falhou')),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              displayName: 'Lisa Silva',
              radius: 24,
              profileImageId: 'image-1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('LS'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('mostra imagem quando a URL é resolvida', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaImageUrlProvider.overrideWith(
            (ref, imageId) async => 'https://cdn.example/$imageId.png',
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              displayName: 'Lisa Silva',
              radius: 24,
              profileImageId: 'image-1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('LS'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);
  });
}
