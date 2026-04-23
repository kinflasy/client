import 'package:client/features/membership/presentation/widgets/member_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders member summary and triggers onTap when provided', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberSummaryCard(
            fullName: 'Maria Silva',
            affiliation: 'MEMBER',
            gender: 'FEMALE',
            birthDate: DateTime(2000, 1, 1),
            onTap: () => tapped = true,
          ),
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
      const MaterialApp(
        home: Scaffold(
          body: MemberSummaryCard(
            fullName: 'Joao Souza',
            affiliation: 'CONGREGATED',
            gender: 'MALE',
          ),
        ),
      ),
    );

    expect(find.text('Joao Souza'), findsOneWidget);
    expect(find.text('Congregados'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
