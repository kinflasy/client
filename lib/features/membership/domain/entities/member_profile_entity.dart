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
    affiliation,
    entryDate,
    integrations,
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
