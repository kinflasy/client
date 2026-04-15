// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_request_model.dart';

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
