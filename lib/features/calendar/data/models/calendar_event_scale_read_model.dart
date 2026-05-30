import 'package:client/features/calendar/domain/entities/calendar_event_scale_entity.dart';

class CalendarEventScaleReadModel {
  const CalendarEventScaleReadModel({
    required this.id,
    required this.lineupId,
    required this.type,
    this.calendarEventId,
    this.collaborationId,
  });

  factory CalendarEventScaleReadModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventScaleReadModel(
      id: _readString(json, 'id') ?? '',
      lineupId:
          _readString(json, 'lineupId') ?? _readNestedId(json['lineup']) ?? '',
      type: CalendarEventScaleType.fromString(_readString(json, 'type')),
      calendarEventId:
          _readString(json, 'calendarEventId') ??
          _readNestedId(json['calendarEvent']),
      collaborationId:
          _readString(json, 'collaborationId') ??
          _readNestedId(json['collaboration']),
    );
  }

  final String id;
  final String lineupId;
  final CalendarEventScaleType type;
  final String? calendarEventId;
  final String? collaborationId;

  CalendarEventScaleEntity toEntity() {
    return CalendarEventScaleEntity(
      id: id,
      lineupId: lineupId,
      type: type,
      calendarEventId: calendarEventId,
      collaborationId: collaborationId,
    );
  }
}

String? _readNestedId(Object? value) {
  if (value is! Map) return null;
  return _readString(Map<String, dynamic>.from(value), 'id');
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
