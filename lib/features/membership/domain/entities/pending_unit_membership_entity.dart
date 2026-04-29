import 'package:equatable/equatable.dart';

class PendingUnitMembershipEntity extends Equatable {
  const PendingUnitMembershipEntity({
    required this.id,
    required this.personId,
    required this.unitId,
    required this.affiliation,
    this.fullName,
    this.unitConfirmationDate,
    this.userConfirmationDate,
  });

  final String id;
  final String personId;
  final String unitId;
  final String affiliation;
  final String? fullName;
  final String? unitConfirmationDate;
  final String? userConfirmationDate;

  @override
  List<Object?> get props => [
    id,
    personId,
    unitId,
    affiliation,
    fullName,
    unitConfirmationDate,
    userConfirmationDate,
  ];
}
