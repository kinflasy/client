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
    final unitId = _readString(json, 'unitId') ?? _readNestedId(json['unit']);
    final departmentId =
        _readString(json, 'departmentId') ?? _readNestedId(json['department']);

    return CalendarEventReadModel(
      id: _readString(json, 'id') ?? '',
      title: _readString(json, 'title') ?? 'Evento',
      description: _readString(json, 'description'),
      startDateTime: _readDateTime(json, 'startDateTime'),
      endDateTime: _readDateTime(json, 'endDateTime'),
      type: _readType(json, unitId: unitId, departmentId: departmentId),
      cardImageId:
          _readString(json, 'cardImageId') ?? _readNestedId(json['cardImage']),
      unitId: unitId,
      departmentId: departmentId,
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

DateTime _readDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is DateTime) return value;
  if (value is List) return _readDateTimeList(value);
  if (value is Map) return _readDateTimeMap(Map<String, dynamic>.from(value));
  return DateTime.parse(value.toString());
}

DateTime _readDateTimeList(List<dynamic> value) {
  if (value.length < 3) {
    throw const FormatException('Lista de data incompleta.');
  }

  return DateTime(
    _readInt(value[0]),
    _readInt(value[1]),
    _readInt(value[2]),
    value.length > 3 ? _readInt(value[3]) : 0,
    value.length > 4 ? _readInt(value[4]) : 0,
    value.length > 5 ? _readInt(value[5]) : 0,
    value.length > 6 ? _readInt(value[6]) ~/ 1000000 : 0,
  );
}

DateTime _readDateTimeMap(Map<String, dynamic> value) {
  final nano = value['nano'];
  final millisecond = value['millisecond'];

  return DateTime(
    _readInt(value['year']),
    _readInt(value['month'] ?? value['monthValue']),
    _readInt(value['day'] ?? value['dayOfMonth']),
    _readInt(value['hour'] ?? 0),
    _readInt(value['minute'] ?? 0),
    _readInt(value['second'] ?? 0),
    millisecond == null
        ? _readInt(nano ?? 0) ~/ 1000000
        : _readInt(millisecond),
  );
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
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

CalendarEventType _readType(
  Map<String, dynamic> json, {
  required String? unitId,
  required String? departmentId,
}) {
  final type = _readString(json, 'type');
  if (type != null && !_isGenericEventDtoType(type)) {
    return CalendarEventType.fromString(type);
  }

  return departmentId == null
      ? CalendarEventType.unit
      : CalendarEventType.department;
}

bool _isGenericEventDtoType(String value) {
  final normalized = value.trim().toUpperCase();
  return normalized == 'CALENDAREVENTDTO' ||
      normalized == 'CALENDAR_EVENT_DTO' ||
      normalized == 'CALENDAR_EVENT';
}

List<VisibilityRuleEntity> _readVisibilityRules(Object? value) {
  final list = _readList(value);
  if (list == null) return const [];

  final rules = <VisibilityRuleEntity>[];
  for (final item in list.whereType<Map>()) {
    try {
      rules.add(VisibilityRuleEntity.fromJson(Map<String, dynamic>.from(item)));
    } on ArgumentError {
      continue;
    }
  }

  return rules;
}

List<dynamic>? _readList(Object? value) {
  if (value is List) return value;
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    for (final key in const ['content', 'items', 'data', 'visibilityRules']) {
      final nested = map[key];
      if (nested is List) return nested;
    }
  }

  return null;
}
