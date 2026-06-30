// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MembershipModel _$MembershipModelFromJson(Map<String, dynamic> json) =>
    _MembershipModel(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      affiliation: json['affiliation'] as String? ?? 'VISITOR',
      unitName: json['unitName'] as String?,
      unitLogoUrl: json['unitLogoUrl'] as String?,
      unitProfileImageId: json['unitProfileImageId'] as String?,
    );

Map<String, dynamic> _$MembershipModelToJson(_MembershipModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unitId': instance.unitId,
      'affiliation': instance.affiliation,
      'unitName': instance.unitName,
      'unitLogoUrl': instance.unitLogoUrl,
      'unitProfileImageId': instance.unitProfileImageId,
    };
