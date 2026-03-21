// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'church_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnitModel _$UnitModelFromJson(Map<String, dynamic> json) => _UnitModel(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  type: json['type'] as String,
  churchId: json['churchId'] as String,
  addressId: json['addressId'] as String,
);

Map<String, dynamic> _$UnitModelToJson(_UnitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'email': instance.email,
      'phone': instance.phone,
      'type': instance.type,
      'churchId': instance.churchId,
      'addressId': instance.addressId,
    };

_ChurchStarterModel _$ChurchStarterModelFromJson(Map<String, dynamic> json) =>
    _ChurchStarterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      acronym: json['acronym'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String,
      unit: UnitModel.fromJson(json['unit'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChurchStarterModelToJson(_ChurchStarterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'acronym': instance.acronym,
      'phone': instance.phone,
      'email': instance.email,
      'unit': instance.unit,
    };
