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

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

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
