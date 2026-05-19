import 'package:equatable/equatable.dart';
import 'package:client/core/domain/enums/integration_type.dart';

class DepartmentParticipantEntity extends Equatable {
  const DepartmentParticipantEntity({
    required this.personId,
    required this.membershipId,
    required this.integrationType,
    this.nickname,
    this.username,
    this.phone,
    this.profileImageId,
    required this.affiliation,
    required this.gender,
    this.birthDate,
    this.age,
  });

  final String personId;
  final String membershipId;
  final IntegrationType integrationType;
  final String? nickname;
  final String? username;
  final String? phone;
  final String? profileImageId;
  final String affiliation;
  final String gender;
  final DateTime? birthDate;
  final int? age;

  String get displayName {
    final trimmedNickname = nickname?.trim();
    if (trimmedNickname != null && trimmedNickname.isNotEmpty) {
      return trimmedNickname;
    }

    final trimmedUsername = username?.trim();
    if (trimmedUsername != null && trimmedUsername.isNotEmpty) {
      return trimmedUsername;
    }

    return 'Participante';
  }

  @override
  List<Object?> get props => [
    personId,
    membershipId,
    integrationType,
    nickname,
    username,
    phone,
    profileImageId,
    affiliation,
    gender,
    birthDate,
    age,
  ];
}
