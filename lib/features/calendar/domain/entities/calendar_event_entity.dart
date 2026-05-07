import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:equatable/equatable.dart';

enum CalendarEventType {
  unit,
  department;

  static CalendarEventType fromString(String value) {
    return switch (value.toUpperCase()) {
      'UNIT' || 'UNIT_CALENDAR_EVENT' => CalendarEventType.unit,
      'DEPARTMENT' ||
      'DEPARTMENT_CALENDAR_EVENT' => CalendarEventType.department,
      _ => throw ArgumentError.value(value, 'value', 'Tipo de evento invalido'),
    };
  }
}

class CalendarEventEntity extends Equatable {
  const CalendarEventEntity({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.type,
    this.description,
    this.cardImageId,
    this.unitId,
    this.departmentId,
    this.visibilityRules = const [],
  });

  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final CalendarEventType type;
  final String? description;
  final String? cardImageId;
  final String? unitId;
  final String? departmentId;
  final List<VisibilityRuleEntity> visibilityRules;

  @override
  List<Object?> get props => [
    id,
    title,
    startDateTime,
    endDateTime,
    type,
    description,
    cardImageId,
    unitId,
    departmentId,
    visibilityRules,
  ];
}
