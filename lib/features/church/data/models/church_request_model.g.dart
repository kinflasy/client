// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'church_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnitRequestModel _$UnitRequestModelFromJson(Map<String, dynamic> json) =>
    _UnitRequestModel(
      name: json['name'] as String,
      slug: json['slug'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      type: json['type'] as String? ?? 'MAIN',
      address: AddressRequestModel.fromJson(
        json['address'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UnitRequestModelToJson(_UnitRequestModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'slug': instance.slug,
      'phone': instance.phone,
      'email': instance.email,
      'type': instance.type,
      'address': instance.address,
    };

_ChurchStarterRequestModel _$ChurchStarterRequestModelFromJson(
  Map<String, dynamic> json,
) => _ChurchStarterRequestModel(
  name: json['name'] as String,
  slug: json['slug'] as String,
  acronym: json['acronym'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String,
  unit: UnitRequestModel.fromJson(json['unit'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChurchStarterRequestModelToJson(
  _ChurchStarterRequestModel instance,
) => <String, dynamic>{
  'name': instance.name,
  'slug': instance.slug,
  'acronym': instance.acronym,
  'phone': instance.phone,
  'email': instance.email,
  'unit': instance.unit,
};
