import 'package:client/features/membership/domain/entities/pending_membership_entity.dart';

class PendingMembershipModel {
  const PendingMembershipModel({
    required this.id,
    required this.unitId,
    required this.affiliation,
    this.personId,
    this.unitConfirmationDate,
    this.userConfirmationDate,
  });

  factory PendingMembershipModel.fromJson(Map<String, dynamic> json) {
    return PendingMembershipModel(
      id: (json['id'] ?? '').toString(),
      unitId: (json['unitId'] ?? '').toString(),
      personId: json['personId']?.toString(),
      affiliation: (json['affiliation'] ?? 'VISITOR').toString(),
      unitConfirmationDate: json['unitConfirmationDate']?.toString(),
      userConfirmationDate: json['userConfirmationDate']?.toString(),
    );
  }

  final String id;
  final String unitId;
  final String? personId;
  final String affiliation;
  final String? unitConfirmationDate;
  final String? userConfirmationDate;

  PendingMembershipEntity toEntity() => PendingMembershipEntity(
    id: id,
    unitId: unitId,
    personId: personId,
    affiliation: affiliation,
    unitConfirmationDate: unitConfirmationDate,
    userConfirmationDate: userConfirmationDate,
  );
}
