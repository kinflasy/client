import 'package:equatable/equatable.dart';

class UnitMemberEntity extends Equatable {
  const UnitMemberEntity({
    required this.membershipId,
    required this.personId,
    required this.fullName,
    this.nickname,
    required this.affiliation,
    required this.gender,
    this.birthDate,
    this.phone,
  });

  final String membershipId;
  final String personId;
  final String fullName;
  final String? nickname;
  final String affiliation;
  final String gender;
  final DateTime? birthDate;
  final String? phone;

  @override
  List<Object?> get props => [
    membershipId,
    personId,
    fullName,
    nickname,
    affiliation,
    gender,
    birthDate,
    phone,
  ];
}
