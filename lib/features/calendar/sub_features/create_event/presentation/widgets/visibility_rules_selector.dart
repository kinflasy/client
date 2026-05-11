import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';

enum _AudienceType { unit, department }

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

  List<VisibilityRuleEntity> get _specificRules {
    return widget.rules.where((rule) => !_isPublicRule(rule)).toList();
  }

  bool get _isPublic => _specificRules.isEmpty;

  @override
  void didUpdateWidget(covariant VisibilityRulesSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureSelectedDepartment();
  }

  void _ensureSelectedDepartment() {
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
    final currentRules = _specificRules;
    if (currentRules.contains(rule)) return;
    widget.onChanged([...currentRules, rule]);
  }

  void _removeRule(VisibilityRuleEntity rule) {
    widget.onChanged(_specificRules.where((item) => item != rule).toList());
  }

  @override
  Widget build(BuildContext context) {
    _ensureSelectedDepartment();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quem pode ver este evento?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            key: const Key('public-visibility-checkbox'),
            value: _isPublic,
            onChanged: (value) {
              if (value ?? false) widget.onChanged(const []);
            },
            title: const Text('Visível para qualquer pessoa'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
          if (_specificRules.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specificRules
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('add-specific-visibility-audience'),
              onPressed: _showAddAudienceSheet,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar público específico'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAudienceSheet() {
    _ensureSelectedDepartment();
    var audienceType = _AudienceType.unit;
    var selectedAffiliation = _affiliation;
    var selectedDepartmentId = _departmentId;
    var selectedIntegrationType = _integrationType;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedDepartmentName = _departmentName(
              selectedDepartmentId,
            );
            final canAdd =
                audienceType == _AudienceType.unit ||
                selectedDepartmentId != null;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Adicionar público',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('close-add-audience-sheet'),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    RadioGroup<_AudienceType>(
                      groupValue: audienceType,
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => audienceType = value);
                      },
                      child: const Column(
                        children: [
                          RadioListTile<_AudienceType>(
                            key: Key('unit-audience-radio'),
                            value: _AudienceType.unit,
                            title: Text('Toda a unidade'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<_AudienceType>(
                            key: Key('department-audience-radio'),
                            value: _AudienceType.department,
                            title: Text('Departamento específico'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (audienceType == _AudienceType.unit)
                      _UnitAudienceFields(
                        affiliation: selectedAffiliation,
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedAffiliation = value);
                        },
                      )
                    else
                      _DepartmentAudienceFields(
                        departments: widget.departments,
                        departmentId: selectedDepartmentId,
                        integrationType: selectedIntegrationType,
                        selectedDepartmentName: selectedDepartmentName,
                        onDepartmentChanged: (value) =>
                            setSheetState(() => selectedDepartmentId = value),
                        onIntegrationTypeChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedIntegrationType = value);
                        },
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      key: const Key('confirm-add-audience-button'),
                      onPressed: canAdd
                          ? () {
                              final rule = audienceType == _AudienceType.unit
                                  ? VisibilityRuleEntity.unit(
                                      unitId: widget.unitId,
                                      affiliation: selectedAffiliation,
                                    )
                                  : VisibilityRuleEntity.department(
                                      departmentId: selectedDepartmentId!,
                                      integrationType: selectedIntegrationType,
                                    );

                              setState(() {
                                _affiliation = selectedAffiliation;
                                _departmentId = selectedDepartmentId;
                                _integrationType = selectedIntegrationType;
                              });
                              _addRule(rule);
                              Navigator.of(context).pop();
                            }
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isPublicRule(VisibilityRuleEntity rule) {
    return rule.type == VisibilityRuleType.user && rule.userId == '*';
  }

  String _ruleLabel(VisibilityRuleEntity rule) {
    return switch (rule.type) {
      VisibilityRuleType.unit =>
        'Toda a unidade - ${_affiliationLabel(rule.affiliation)}',
      VisibilityRuleType.department =>
        '${_departmentName(rule.departmentId)} - ${_integrationLabel(rule.integrationType)}',
      VisibilityRuleType.user => rule.userId == null ? 'Usuário' : rule.userId!,
      VisibilityRuleType.church =>
        'Igreja - ${_affiliationLabel(rule.affiliation)}',
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

class _UnitAudienceFields extends StatelessWidget {
  const _UnitAudienceFields({
    required this.affiliation,
    required this.onChanged,
  });

  final Affiliation affiliation;
  final ValueChanged<Affiliation?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Affiliation>(
          key: const Key('unit-affiliation-dropdown'),
          initialValue: affiliation,
          decoration: const InputDecoration(
            labelText: 'Vínculo',
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
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Text(
          _unitHelperText(affiliation),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _unitHelperText(Affiliation affiliation) {
    return switch (affiliation) {
      Affiliation.visitor => 'Visitantes, congregados e membros poderão ver.',
      Affiliation.congregated => 'Congregados e membros poderão ver.',
      Affiliation.member => 'Apenas membros poderão ver.',
      _ => 'Selecione quem poderá ver.',
    };
  }
}

class _DepartmentAudienceFields extends StatelessWidget {
  const _DepartmentAudienceFields({
    required this.departments,
    required this.departmentId,
    required this.integrationType,
    required this.selectedDepartmentName,
    required this.onDepartmentChanged,
    required this.onIntegrationTypeChanged,
  });

  final List<DepartmentEntity> departments;
  final String? departmentId;
  final IntegrationType integrationType;
  final String selectedDepartmentName;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<IntegrationType?> onIntegrationTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('audience-department-dropdown'),
          initialValue: departmentId,
          decoration: const InputDecoration(
            labelText: 'Departamento',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: departments
              .map(
                (department) => DropdownMenuItem(
                  value: department.id,
                  child: Text(department.name),
                ),
              )
              .toList(),
          onChanged: departments.isEmpty ? null : onDepartmentChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<IntegrationType>(
          key: const Key('audience-integration-type-dropdown'),
          initialValue: integrationType,
          decoration: const InputDecoration(
            labelText: 'Papel',
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
          onChanged: onIntegrationTypeChanged,
        ),
        const SizedBox(height: 8),
        Text(
          _departmentHelperText(integrationType, selectedDepartmentName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _departmentHelperText(
    IntegrationType integrationType,
    String departmentName,
  ) {
    return switch (integrationType) {
      IntegrationType.observer =>
        'Apenas observadores do $departmentName poderão ver.',
      IntegrationType.consultant =>
        'Consultores e acima do $departmentName poderão ver.',
      IntegrationType.integrant =>
        'Integrantes, auxiliares e líderes do $departmentName poderão ver.',
      IntegrationType.assistant =>
        'Auxiliares e líderes do $departmentName poderão ver.',
      IntegrationType.leader =>
        'Apenas líderes do $departmentName poderão ver.',
    };
  }
}
