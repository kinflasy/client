import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/sub_features/create_event/presentation/widgets/visibility_rules_selector.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe estado inicial público com lista vazia', (tester) async {
    await tester.pumpWidget(_build(rules: const [], onChanged: (_) {}));

    expect(find.text('Quem pode ver este evento?'), findsOneWidget);
    expect(find.text('Visível para qualquer pessoa'), findsOneWidget);
    expect(_publicCheckbox(tester).value, isTrue);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('marcar público limpa regras específicas', (tester) async {
    var rules = const [
      VisibilityRuleEntity.unit(
        unitId: 'unit-1',
        affiliation: Affiliation.member,
      ),
    ];
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    await tester.tap(find.byKey(const Key('public-visibility-checkbox')));
    await tester.pump();

    expect(rules, isEmpty);
  });

  testWidgets('adicionar regra específica cria chip de unidade', (
    tester,
  ) async {
    var rules = const [VisibilityRuleEntity.user(userId: '*')];
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    await tester.tap(find.byKey(const Key('add-specific-visibility-audience')));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar público'), findsOneWidget);
    expect(
      find.text('Visitantes, congregados e membros poderão ver.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm-add-audience-button')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    expect(rules, hasLength(1));
    expect(rules.single.type, VisibilityRuleType.unit);
    expect(find.text('Toda a unidade - Visitante'), findsOneWidget);
    expect(find.text('Usuário: todos'), findsNothing);
  });

  testWidgets('adicionar regra de departamento cria chip correto', (
    tester,
  ) async {
    var rules = <VisibilityRuleEntity>[];
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    await tester.tap(find.byKey(const Key('add-specific-visibility-audience')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('department-audience-radio')));
    await tester.pumpAndSettle();

    expect(
      find.text('Integrantes, auxiliares e líderes do Louvor poderão ver.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm-add-audience-button')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    expect(rules, hasLength(1));
    expect(rules.single.type, VisibilityRuleType.department);
    expect(rules.single.departmentId, 'dep-1');
    expect(find.text('Louvor - Integrante'), findsOneWidget);
  });

  testWidgets('exibe chip de departamento com label esperado', (tester) async {
    await tester.pumpWidget(
      _build(
        rules: const [
          VisibilityRuleEntity.department(
            departmentId: 'dep-1',
            integrationType: IntegrationType.integrant,
          ),
        ],
        onChanged: (_) {},
      ),
    );

    expect(find.text('Louvor - Integrante'), findsOneWidget);
  });

  testWidgets('remove chip e atualiza lista', (tester) async {
    var rules = const [
      VisibilityRuleEntity.department(
        departmentId: 'dep-1',
        integrationType: IntegrationType.integrant,
      ),
    ];
    await tester.pumpWidget(
      _build(rules: rules, onChanged: (value) => rules = value),
    );

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();

    expect(rules, isEmpty);
  });

  testWidgets('USER * não aparece como chip', (tester) async {
    await tester.pumpWidget(
      _build(
        rules: const [VisibilityRuleEntity.user(userId: '*')],
        onChanged: (_) {},
      ),
    );

    expect(_publicCheckbox(tester).value, isTrue);
    expect(find.byType(InputChip), findsNothing);
    expect(find.text('*'), findsNothing);
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

CheckboxListTile _publicCheckbox(WidgetTester tester) {
  return tester.widget<CheckboxListTile>(
    find.byKey(const Key('public-visibility-checkbox')),
  );
}
