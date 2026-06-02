import 'package:client/features/scale/domain/entities/scale_item_entity.dart';

class ScaleItemReadModel {
  const ScaleItemReadModel({
    required this.id,
    required this.scaleId,
    required this.roleId,
    required this.personId,
  });

  factory ScaleItemReadModel.fromJson(Map<String, dynamic> json) {
    return ScaleItemReadModel(
      id: _readString(json, 'id') ?? '',
      scaleId:
          _readString(json, 'scaleId') ?? _readNestedId(json['scale']) ?? '',
      roleId: _readString(json, 'roleId') ?? _readNestedId(json['role']) ?? '',
      personId:
          _readString(json, 'personId') ?? _readNestedId(json['person']) ?? '',
    );
  }

  final String id;
  final String scaleId;
  final String roleId;
  final String personId;

  ScaleItemEntity toEntity() {
    return ScaleItemEntity(
      id: id,
      scaleId: scaleId,
      roleId: roleId,
      personId: personId,
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
