import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:equatable/equatable.dart';

enum CalendarEventScaleType {
  owner,
  collaborator;

  static CalendarEventScaleType fromString(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'COLLABORATOR' => CalendarEventScaleType.collaborator,
      _ => CalendarEventScaleType.owner,
    };
  }
}

class CalendarEventScaleEntity extends Equatable {
  const CalendarEventScaleEntity({
    required this.id,
    required this.lineupId,
    required this.type,
    this.calendarEventId,
    this.collaborationId,
  });

  final String id;
  final String lineupId;
  final CalendarEventScaleType type;
  final String? calendarEventId;
  final String? collaborationId;

  @override
  List<Object?> get props => [
    id,
    lineupId,
    type,
    calendarEventId,
    collaborationId,
  ];
}

class DepartmentCalendarEventScaleEntity extends Equatable {
  const DepartmentCalendarEventScaleEntity({
    required this.scale,
    required this.calendarEvent,
  });

  final CalendarEventScaleEntity scale;
  final CalendarEventEntity calendarEvent;

  @override
  List<Object?> get props => [scale, calendarEvent];
}
