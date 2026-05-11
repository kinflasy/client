import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:equatable/equatable.dart';

enum VisibilityRuleType {
  user,
  unit,
  church,
  department;

  static VisibilityRuleType fromString(String value) {
    return switch (value.toUpperCase()) {
      'USER' => VisibilityRuleType.user,
      'UNIT' => VisibilityRuleType.unit,
      'CHURCH' => VisibilityRuleType.church,
      'DEPARTMENT' => VisibilityRuleType.department,
      _ => throw ArgumentError.value(value, 'value', 'Tipo de regra invalido'),
    };
  }
}

class VisibilityRuleEntity extends Equatable {
  const VisibilityRuleEntity._({
    required this.type,
    this.userId,
    this.unitId,
    this.churchId,
    this.departmentId,
    this.affiliation,
    this.integrationType,
  });

  const VisibilityRuleEntity.user({required String userId})
    : this._(type: VisibilityRuleType.user, userId: userId);

  const VisibilityRuleEntity.unit({
    required String unitId,
    required Affiliation affiliation,
  }) : this._(
         type: VisibilityRuleType.unit,
         unitId: unitId,
         affiliation: affiliation,
       );

  const VisibilityRuleEntity.church({
    required String churchId,
    required Affiliation affiliation,
  }) : this._(
         type: VisibilityRuleType.church,
         churchId: churchId,
         affiliation: affiliation,
       );

  const VisibilityRuleEntity.department({
    required String departmentId,
    required IntegrationType integrationType,
  }) : this._(
         type: VisibilityRuleType.department,
         departmentId: departmentId,
         integrationType: integrationType,
       );

  factory VisibilityRuleEntity.fromJson(Map<String, dynamic> json) {
    final type = VisibilityRuleType.fromString(_readString(json, 'type') ?? '');
    return switch (type) {
      VisibilityRuleType.user => VisibilityRuleEntity.user(
        userId: _readString(json, 'userId') ?? '*',
      ),
      VisibilityRuleType.unit => VisibilityRuleEntity.unit(
        unitId: _readString(json, 'unitId') ?? '',
        affiliation: _affiliationFromJson(json['affiliation']),
      ),
      VisibilityRuleType.church => VisibilityRuleEntity.church(
        churchId: _readString(json, 'churchId') ?? '',
        affiliation: _affiliationFromJson(json['affiliation']),
      ),
      VisibilityRuleType.department => VisibilityRuleEntity.department(
        departmentId: _readString(json, 'departmentId') ?? '',
        integrationType: IntegrationType.fromString(
          _readString(json, 'integrationType') ?? '',
        ),
      ),
    };
  }

  final VisibilityRuleType type;
  final String? userId;
  final String? unitId;
  final String? churchId;
  final String? departmentId;
  final Affiliation? affiliation;
  final IntegrationType? integrationType;

  Map<String, dynamic> toJson() {
    return switch (type) {
      VisibilityRuleType.user => {'type': 'USER', 'userId': userId ?? '*'},
      VisibilityRuleType.unit => {
        'type': 'UNIT',
        'unitId': unitId,
        'affiliation': _affiliationToJson(affiliation),
      },
      VisibilityRuleType.church => {
        'type': 'CHURCH',
        'churchId': churchId,
        'affiliation': _affiliationToJson(affiliation),
      },
      VisibilityRuleType.department => {
        'type': 'DEPARTMENT',
        'departmentId': departmentId,
        'integrationType': integrationType?.name.toUpperCase(),
      },
    };
  }

  @override
  List<Object?> get props => [
    type,
    userId,
    unitId,
    churchId,
    departmentId,
    affiliation,
    integrationType,
  ];
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Affiliation _affiliationFromJson(Object? value) {
  final normalized = value?.toString().toUpperCase();
  return switch (normalized) {
    'VISITOR' => Affiliation.visitor,
    'CONGREGATED' => Affiliation.congregated,
    'MEMBER' => Affiliation.member,
    _ => Affiliation.visitor,
  };
}

String? _affiliationToJson(Affiliation? value) {
  return switch (value) {
    Affiliation.visitor => 'VISITOR',
    Affiliation.congregated => 'CONGREGATED',
    Affiliation.member => 'MEMBER',
    _ => value?.name.toUpperCase(),
  };
}
