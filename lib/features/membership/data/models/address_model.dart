import 'package:client/features/membership/domain/entities/member_profile_entity.dart';

class AddressModel {
  const AddressModel({
    required this.id,
    this.zip,
    this.country,
    this.state,
    this.city,
    this.neighborhood,
    this.street,
    this.number,
    this.complement,
    this.reference,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: (json['id'] ?? '').toString(),
      zip: json['zip']?.toString(),
      country: json['country']?.toString(),
      state: json['state']?.toString(),
      city: json['city']?.toString(),
      neighborhood: json['neighborhood']?.toString(),
      street: json['street']?.toString(),
      number: json['number']?.toString(),
      complement: json['complement']?.toString(),
      reference: json['reference']?.toString(),
    );
  }

  final String id;
  final String? zip;
  final String? country;
  final String? state;
  final String? city;
  final String? neighborhood;
  final String? street;
  final String? number;
  final String? complement;
  final String? reference;

  String? format() {
    final primaryParts = [
      if (_hasText(street)) street!.trim(),
      if (_hasText(number)) number!.trim(),
      if (_hasText(neighborhood)) neighborhood!.trim(),
      if (_hasText(city)) city!.trim(),
      if (_hasText(state)) state!.trim(),
      if (_hasText(country)) country!.trim(),
    ];
    final secondaryParts = [
      if (_hasText(complement)) complement!.trim(),
      if (_hasText(reference)) reference!.trim(),
      if (_hasText(zip)) zip!.trim(),
    ];

    final formatted = [
      if (primaryParts.isNotEmpty) primaryParts.join(', '),
      if (secondaryParts.isNotEmpty) secondaryParts.join(' - '),
    ].join(' | ');

    return formatted.isEmpty ? null : formatted;
  }

  AddressDetailsEntity toEntity() {
    return AddressDetailsEntity(
      id: id,
      zip: zip,
      country: country,
      state: state,
      city: city,
      neighborhood: neighborhood,
      street: street,
      number: number,
      complement: complement,
      reference: reference,
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
