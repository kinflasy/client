import 'package:client/core/address/address_value.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:equatable/equatable.dart';

class MemberProfileEntity extends Equatable {
  const MemberProfileEntity({
    required this.personId,
    required this.membershipId,
    required this.personType,
    required this.fullName,
    this.nickname,
    required this.gender,
    this.birthDate,
    this.age,
    this.phone,
    this.email,
    this.address,
    this.addressDetails,
    required this.affiliation,
    this.entryDate,
    this.profileImageId,
    this.integrations = const [],
  });

  final String personId;
  final String membershipId;
  final PersonType personType;
  final String fullName;
  final String? nickname;
  final String gender;
  final DateTime? birthDate;
  final int? age;
  final String? phone;
  final String? email;
  final String? address;
  final AddressDetailsEntity? addressDetails;
  final String affiliation;
  final DateTime? entryDate;
  final String? profileImageId;
  final List<MemberProfileIntegrationEntity> integrations;

  @override
  List<Object?> get props => [
    personId,
    membershipId,
    personType,
    fullName,
    nickname,
    gender,
    birthDate,
    age,
    phone,
    email,
    address,
    addressDetails,
    affiliation,
    entryDate,
    profileImageId,
    integrations,
  ];
}

class AddressDetailsEntity extends Equatable {
  const AddressDetailsEntity({
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

  AddressValue toValue() {
    return AddressValue(
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

  @override
  List<Object?> get props => [
    id,
    zip,
    country,
    state,
    city,
    neighborhood,
    street,
    number,
    complement,
    reference,
  ];
}

class MemberProfileIntegrationEntity extends Equatable {
  const MemberProfileIntegrationEntity({
    required this.departmentId,
    required this.departmentName,
    required this.departmentType,
    required this.integrationType,
  });

  final String departmentId;
  final String departmentName;
  final String departmentType;
  final IntegrationType integrationType;

  @override
  List<Object?> get props => [
    departmentId,
    departmentName,
    departmentType,
    integrationType,
  ];
}
