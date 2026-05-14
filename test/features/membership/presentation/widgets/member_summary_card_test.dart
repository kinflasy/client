import 'package:client/core/media/media_providers.dart';
import 'package:client/features/membership/presentation/widgets/member_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Widget child) {
    return ProviderScope(
      overrides: [
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://cdn.example/$imageId.png',
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('renders member summary and triggers onTap when provided', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      buildApp(
        MemberSummaryCard(
          fullName: 'Maria Silva',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
          birthDate: DateTime(2000, 1, 1),
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.textContaining('Membros'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('renders safely when onTap is absent', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const MemberSummaryCard(
          fullName: 'Joao Souza',
          affiliation: 'CONGREGATED',
          gender: 'MALE',
        ),
      ),
    );

    expect(find.text('Joao Souza'), findsOneWidget);
    expect(find.text('Congregados'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('prefers provided age over birthDate calculation', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        MemberSummaryCard(
          fullName: 'Ana Lima',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
          birthDate: DateTime(2000, 1, 1),
          age: 99,
        ),
      ),
    );

    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Membros · 99 anos'), findsOneWidget);
  });

  testWidgets('renders profile image when profileImageId is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const MemberSummaryCard(
          fullName: 'Ana Lima',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
          profileImageId: 'image-1',
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('AL'), findsNothing);
  });
}
