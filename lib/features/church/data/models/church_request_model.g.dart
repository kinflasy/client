// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'church_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AddressRequestModel _$AddressRequestModelFromJson(Map<String, dynamic> json) =>
    _AddressRequestModel(
      zip: json['zip'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      neighborhood: json['neighborhood'] as String?,
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      reference: json['reference'] as String?,
    );

Map<String, dynamic> _$AddressRequestModelToJson(
  _AddressRequestModel instance,
) => <String, dynamic>{
  'zip': instance.zip,
  'country': instance.country,
  'state': instance.state,
  'city': instance.city,
  'neighborhood': instance.neighborhood,
  'street': instance.street,
  'number': instance.number,
  'complement': instance.complement,
  'reference': instance.reference,
};

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
