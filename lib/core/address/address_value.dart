import 'package:client/core/address/address_utils.dart';
import 'package:flutter/foundation.dart';

@immutable
class AddressValue {
  const AddressValue({
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

  const AddressValue.empty()
    : zip = null,
      country = null,
      state = null,
      city = null,
      neighborhood = null,
      street = null,
      number = null,
      complement = null,
      reference = null;

  final String? zip;
  final String? country;
  final String? state;
  final String? city;
  final String? neighborhood;
  final String? street;
  final String? number;
  final String? complement;
  final String? reference;

  bool get isBlank =>
      !hasText(zip) &&
      !hasText(country) &&
      !hasText(state) &&
      !hasText(city) &&
      !hasText(neighborhood) &&
      !hasText(street) &&
      !hasText(number) &&
      !hasText(complement) &&
      !hasText(reference);

  String? format() => formatAddressParts(
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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AddressValue &&
            runtimeType == other.runtimeType &&
            zip == other.zip &&
            country == other.country &&
            state == other.state &&
            city == other.city &&
            neighborhood == other.neighborhood &&
            street == other.street &&
            number == other.number &&
            complement == other.complement &&
            reference == other.reference;
  }

  @override
  int get hashCode => Object.hash(
    zip,
    country,
    state,
    city,
    neighborhood,
    street,
    number,
    complement,
    reference,
  );
}
