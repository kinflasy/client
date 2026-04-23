import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/presentation/widgets/department_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders department card without onTap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DepartmentCard(
            department: DepartmentEntity(
              id: 'dep-1',
              name: 'Louvor',
              slug: 'louvor',
              type: 'MINISTRY',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('@louvor'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('calls onTap when provided', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentCard(
            department: const DepartmentEntity(
              id: 'dep-2',
              name: 'Secretaria',
              type: 'ADMINISTRATIVE',
            ),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
