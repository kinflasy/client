import 'package:client/core/address/address_request_model.dart';
import 'package:client/core/address/address_utils.dart';
import 'package:client/core/address/address_value.dart';
import 'package:flutter/foundation.dart';

@immutable
class AddressFormState {
  const AddressFormState({
    this.zip = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.neighborhood = '',
    this.street = '',
    this.number = '',
    this.complement = '',
    this.reference = '',
  });

  factory AddressFormState.fromValue(AddressValue? value) {
    return AddressFormState(
      zip: value?.zip ?? '',
      country: value?.country ?? '',
      state: value?.state ?? '',
      city: value?.city ?? '',
      neighborhood: value?.neighborhood ?? '',
      street: value?.street ?? '',
      number: value?.number ?? '',
      complement: value?.complement ?? '',
      reference: value?.reference ?? '',
    );
  }

  final String zip;
  final String country;
  final String state;
  final String city;
  final String neighborhood;
  final String street;
  final String number;
  final String complement;
  final String reference;

  AddressFormState copyWith({
    String? zip,
    String? country,
    String? state,
    String? city,
    String? neighborhood,
    String? street,
    String? number,
    String? complement,
    String? reference,
  }) {
    return AddressFormState(
      zip: zip ?? this.zip,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      reference: reference ?? this.reference,
    );
  }

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

  AddressRequestModel? toRequestOrNull() {
    if (isBlank) return null;

    return AddressRequestModel(
      zip: normalizeAddressField(zip),
      country: normalizeAddressField(country),
      state: normalizeAddressField(state),
      city: normalizeAddressField(city),
      neighborhood: normalizeAddressField(neighborhood),
      street: normalizeAddressField(street),
      number: normalizeAddressField(number),
      complement: normalizeAddressField(complement),
      reference: normalizeAddressField(reference),
    );
  }

  AddressValue toValue() {
    return AddressValue(
      zip: normalizeAddressField(zip),
      country: normalizeAddressField(country),
      state: normalizeAddressField(state),
      city: normalizeAddressField(city),
      neighborhood: normalizeAddressField(neighborhood),
      street: normalizeAddressField(street),
      number: normalizeAddressField(number),
      complement: normalizeAddressField(complement),
      reference: normalizeAddressField(reference),
    );
  }
}
