import 'package:client/features/calendar/domain/entities/event_collaboration_entity.dart';
import 'package:client/features/church/data/models/church_read_models.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';

class EventCollaborationReadModel {
  const EventCollaborationReadModel({
    required this.id,
    required this.calendarEventId,
    required this.departmentId,
    this.department,
  });

  factory EventCollaborationReadModel.fromJson(Map<String, dynamic> json) {
    final directDepartmentJson = _looksLikeDepartment(json) ? json : null;
    final departmentJson = _readMap(json['department']) ?? directDepartmentJson;
    final departmentModel = departmentJson == null
        ? null
        : DepartmentReadModel.fromJson(departmentJson);

    return EventCollaborationReadModel(
      id: directDepartmentJson == null ? _readString(json, 'id') ?? '' : '',
      calendarEventId:
          _readString(json, 'calendarEventId') ??
          _readNestedId(json['calendarEvent']) ??
          '',
      departmentId:
          _readString(json, 'departmentId') ??
          _readNestedId(json['department']) ??
          _readString(directDepartmentJson ?? const {}, 'id') ??
          '',
      department: departmentModel == null
          ? null
          : DepartmentEntity(
              id: departmentModel.id,
              name: departmentModel.name,
              slug: departmentModel.slug,
              type: departmentModel.type,
            ),
    );
  }

  final String id;
  final String calendarEventId;
  final String departmentId;
  final DepartmentEntity? department;

  EventCollaborationEntity toEntity() {
    return EventCollaborationEntity(
      id: id,
      calendarEventId: calendarEventId,
      departmentId: departmentId,
      department: department,
    );
  }
}

bool _looksLikeDepartment(Map<String, dynamic> json) {
  return json.containsKey('name') &&
      !json.containsKey('departmentId') &&
      !json.containsKey('calendarEventId') &&
      !json.containsKey('calendarEvent') &&
      !json.containsKey('department');
}

Map<String, dynamic>? _readMap(Object? value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

String? _readNestedId(Object? value) {
  final map = _readMap(value);
  if (map == null) return null;
  return _readString(map, 'id');
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
