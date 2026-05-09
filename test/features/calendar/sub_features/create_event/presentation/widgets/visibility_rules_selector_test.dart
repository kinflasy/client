import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/sub_features/create_event/presentation/widgets/visibility_rules_selector.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('adiciona regra UNIT', (tester) async {
    var rules = <VisibilityRuleEntity>[];
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    await tester.tap(find.byKey(const Key('add-unit-visibility-rule')));
    await tester.pump();

    expect(rules, hasLength(1));
    expect(rules.single.type, VisibilityRuleType.unit);
  });

  testWidgets('adiciona regra DEPARTMENT', (tester) async {
    var rules = <VisibilityRuleEntity>[];
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    await tester.tap(find.byKey(const Key('add-department-visibility-rule')));
    await tester.pump();

    expect(rules, hasLength(1));
    expect(rules.single.type, VisibilityRuleType.department);
    expect(rules.single.departmentId, 'dep-1');
  });

  testWidgets('remove regra', (tester) async {
    var rules = const [VisibilityRuleEntity.user(userId: '*')];
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();

    expect(rules, isEmpty);
  });
}

Widget _build({
  required List<VisibilityRuleEntity> rules,
  required ValueChanged<List<VisibilityRuleEntity>> onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: VisibilityRulesSelector(
        unitId: 'unit-1',
        departments: const [DepartmentEntity(id: 'dep-1', name: 'Louvor')],
        rules: rules,
        onChanged: onChanged,
      ),
    ),
  );
}
