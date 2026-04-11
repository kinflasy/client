// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnitMemberModel _$UnitMemberModelFromJson(Map<String, dynamic> json) =>
    _UnitMemberModel(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      person: UnitMemberPersonModel.fromJson(
        json['person'] as Map<String, dynamic>,
      ),
      affiliation: json['affiliation'] as String,
    );

Map<String, dynamic> _$UnitMemberModelToJson(_UnitMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unitId': instance.unitId,
      'person': instance.person,
      'affiliation': instance.affiliation,
    };

_UnitMemberPersonModel _$UnitMemberPersonModelFromJson(
  Map<String, dynamic> json,
) => _UnitMemberPersonModel(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  nickname: json['nickname'] as String?,
  gender: json['gender'] as String,
  birthDate: json['birthDate'] as String?,
  phone: json['phone'] as String?,
  addressId: json['addressId'] as String?,
);

Map<String, dynamic> _$UnitMemberPersonModelToJson(
  _UnitMemberPersonModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'nickname': instance.nickname,
  'gender': instance.gender,
  'birthDate': instance.birthDate,
  'phone': instance.phone,
  'addressId': instance.addressId,
};
