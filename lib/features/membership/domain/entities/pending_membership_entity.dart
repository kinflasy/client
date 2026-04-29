import 'package:equatable/equatable.dart';

class PendingMembershipEntity extends Equatable {
  const PendingMembershipEntity({
    required this.id,
    required this.unitId,
    required this.affiliation,
    this.personId,
    this.unitConfirmationDate,
    this.userConfirmationDate,
  });

  final String id;
  final String unitId;
  final String affiliation;
  final String? personId;
  final String? unitConfirmationDate;
  final String? userConfirmationDate;

  bool matchesUnit(String currentUnitId) => unitId == currentUnitId;

  bool matchesAffiliation(String currentAffiliation) =>
      affiliation.toUpperCase() == currentAffiliation.toUpperCase();

  @override
  List<Object?> get props => [
    id,
    unitId,
    personId,
    affiliation,
    unitConfirmationDate,
    userConfirmationDate,
  ];
}
