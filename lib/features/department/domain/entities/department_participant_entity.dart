import 'package:equatable/equatable.dart';

class DepartmentParticipantEntity extends Equatable {
  const DepartmentParticipantEntity({
    required this.personId,
    this.nickname,
    this.username,
    required this.affiliation,
    required this.gender,
    this.birthDate,
    this.age,
  });

  final String personId;
  final String? nickname;
  final String? username;
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
    nickname,
    username,
    affiliation,
    gender,
    birthDate,
    age,
  ];
}
