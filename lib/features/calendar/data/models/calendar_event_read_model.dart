import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';

class CalendarEventReadModel {
  const CalendarEventReadModel({
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

  factory CalendarEventReadModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventReadModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Evento',
      description: json['description'] as String?,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      type: CalendarEventType.fromString(json['type'] as String? ?? ''),
      cardImageId: json['cardImageId'] as String?,
      unitId: json['unitId'] as String?,
      departmentId: json['departmentId'] as String?,
      visibilityRules: _readVisibilityRules(json['visibilityRules']),
    );
  }

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

  CalendarEventEntity toEntity() {
    return CalendarEventEntity(
      id: id,
      title: title,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      type: type,
      description: description,
      cardImageId: cardImageId,
      unitId: unitId,
      departmentId: departmentId,
      visibilityRules: visibilityRules,
    );
  }
}

List<VisibilityRuleEntity> _readVisibilityRules(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .map(VisibilityRuleEntity.fromJson)
      .toList();
}
