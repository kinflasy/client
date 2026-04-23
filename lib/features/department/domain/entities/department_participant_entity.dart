import 'package:equatable/equatable.dart';

class DepartmentParticipantEntity extends Equatable {
  const DepartmentParticipantEntity({
    required this.personId,
    required this.fullName,
    required this.affiliation,
    required this.gender,
    this.birthDate,
  });

  final String personId;
  final String fullName;
  final String affiliation;
  final String gender;
  final DateTime? birthDate;

  @override
  List<Object?> get props => [
    personId,
    fullName,
    affiliation,
    gender,
    birthDate,
  ];
}