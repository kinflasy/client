import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';

class CalendarEventRequestModel {
  const CalendarEventRequestModel({
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.visibilityRules,
    this.description,
  });

  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<VisibilityRuleEntity> visibilityRules;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'visibilityRules': visibilityRules.map((rule) => rule.toJson()).toList(),
    };
  }
}
