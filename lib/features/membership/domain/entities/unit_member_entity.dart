import 'package:equatable/equatable.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';

class UnitMemberEntity extends Equatable {
  const UnitMemberEntity({
    required this.membershipId,
    required this.personId,
    required this.personType,
    required this.fullName,
    this.nickname,
    required this.affiliation,
    required this.gender,
    this.birthDate,
    this.phone,
    this.addressId,
    this.profileImageId,
  });

  final String membershipId;
  final String personId;
  final PersonType personType;
  final String fullName;
  final String? nickname;
  final String affiliation;
  final String gender;
  final DateTime? birthDate;
  final String? phone;
  final String? addressId;
  final String? profileImageId;

  @override
  List<Object?> get props => [
    membershipId,
    personId,
    personType,
    fullName,
    nickname,
    affiliation,
    gender,
    birthDate,
    phone,
    addressId,
    profileImageId,
  ];
}
