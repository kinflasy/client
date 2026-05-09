import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';

class VisibilityRulesSelector extends StatefulWidget {
  const VisibilityRulesSelector({
    super.key,
    required this.unitId,
    required this.departments,
    required this.rules,
    required this.onChanged,
  });

  final String unitId;
  final List<DepartmentEntity> departments;
  final List<VisibilityRuleEntity> rules;
  final ValueChanged<List<VisibilityRuleEntity>> onChanged;

  @override
  State<VisibilityRulesSelector> createState() =>
      _VisibilityRulesSelectorState();
}

class _VisibilityRulesSelectorState extends State<VisibilityRulesSelector> {
  Affiliation _affiliation = Affiliation.visitor;
  IntegrationType _integrationType = IntegrationType.integrant;
  String? _departmentId;

  @override
  void didUpdateWidget(covariant VisibilityRulesSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_departmentId == null ||
        !widget.departments.any(
          (department) => department.id == _departmentId,
        )) {
      _departmentId = widget.departments.isEmpty
          ? null
          : widget.departments.first.id;
    }
  }

  void _addRule(VisibilityRuleEntity rule) {
    if (widget.rules.contains(rule)) return;
    widget.onChanged([...widget.rules, rule]);
  }

  void _removeRule(VisibilityRuleEntity rule) {
    widget.onChanged(widget.rules.where((item) => item != rule).toList());
  }

  @override
  Widget build(BuildContext context) {
    _departmentId ??= widget.departments.isEmpty
        ? null
        : widget.departments.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Visibilidade',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Adicione quem poderá ver este evento.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Affiliation>(
          initialValue: _affiliation,
          decoration: const InputDecoration(
            labelText: 'Vínculo na unidade',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(
              value: Affiliation.visitor,
              child: Text('Visitante'),
            ),
            DropdownMenuItem(
              value: Affiliation.congregated,
              child: Text('Congregado'),
            ),
            DropdownMenuItem(value: Affiliation.member, child: Text('Membro')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _affiliation = value);
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('add-unit-visibility-rule'),
          onPressed: () => _addRule(
            VisibilityRuleEntity.unit(
              unitId: widget.unitId,
              affiliation: _affiliation,
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar regra da unidade'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _departmentId,
          decoration: const InputDecoration(
            labelText: 'Departamento',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: widget.departments
              .map(
                (department) => DropdownMenuItem(
                  value: department.id,
                  child: Text(department.name),
                ),
              )
              .toList(),
          onChanged: widget.departments.isEmpty
              ? null
              : (value) => setState(() => _departmentId = value),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<IntegrationType>(
          initialValue: _integrationType,
          decoration: const InputDecoration(
            labelText: 'Papel no departamento',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(
              value: IntegrationType.observer,
              child: Text('Observador'),
            ),
            DropdownMenuItem(
              value: IntegrationType.consultant,
              child: Text('Consultor'),
            ),
            DropdownMenuItem(
              value: IntegrationType.integrant,
              child: Text('Integrante'),
            ),
            DropdownMenuItem(
              value: IntegrationType.assistant,
              child: Text('Auxiliar'),
            ),
            DropdownMenuItem(
              value: IntegrationType.leader,
              child: Text('Líder'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _integrationType = value);
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('add-department-visibility-rule'),
          onPressed: _departmentId == null
              ? null
              : () => _addRule(
                  VisibilityRuleEntity.department(
                    departmentId: _departmentId!,
                    integrationType: _integrationType,
                  ),
                ),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar regra do departamento'),
        ),
        const SizedBox(height: 12),
        if (widget.rules.isEmpty)
          const Text(
            'Nenhuma regra adicionada.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.rules
                .map(
                  (rule) => InputChip(
                    label: Text(_ruleLabel(rule)),
                    deleteIcon: Icon(
                      Icons.close,
                      key: Key('remove-visibility-rule-${rule.hashCode}'),
                    ),
                    onDeleted: () => _removeRule(rule),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  String _ruleLabel(VisibilityRuleEntity rule) {
    return switch (rule.type) {
      VisibilityRuleType.unit =>
        'Unidade: ${_affiliationLabel(rule.affiliation)}',
      VisibilityRuleType.department =>
        '${_departmentName(rule.departmentId)}: ${_integrationLabel(rule.integrationType)}',
      VisibilityRuleType.user =>
        'Usuário: ${rule.userId == '*' ? 'todos' : rule.userId}',
      VisibilityRuleType.church =>
        'Igreja: ${_affiliationLabel(rule.affiliation)}',
    };
  }

  String _departmentName(String? departmentId) {
    for (final department in widget.departments) {
      if (department.id == departmentId) return department.name;
    }
    return 'Departamento';
  }

  String _affiliationLabel(Affiliation? affiliation) {
    return switch (affiliation) {
      Affiliation.visitor => 'Visitante',
      Affiliation.congregated => 'Congregado',
      Affiliation.member => 'Membro',
      _ => 'Vínculo',
    };
  }

  String _integrationLabel(IntegrationType? integrationType) {
    return switch (integrationType) {
      IntegrationType.observer => 'Observador',
      IntegrationType.consultant => 'Consultor',
      IntegrationType.integrant => 'Integrante',
      IntegrationType.assistant => 'Auxiliar',
      IntegrationType.leader => 'Líder',
      _ => 'Papel',
    };
  }
}
