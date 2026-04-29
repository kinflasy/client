import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';

class PendingUnitMembershipModel {
  const PendingUnitMembershipModel({
    required this.id,
    required this.personId,
    required this.unitId,
    required this.affiliation,
    this.fullName,
    this.unitConfirmationDate,
    this.userConfirmationDate,
  });

  factory PendingUnitMembershipModel.fromJson(Map<String, dynamic> json) {
    final person = json['person'];
    final personMap = person is Map
        ? Map<String, dynamic>.from(person)
        : const <String, dynamic>{};
    final unit = json['unit'];
    final unitMap = unit is Map
        ? Map<String, dynamic>.from(unit)
        : const <String, dynamic>{};

    return PendingUnitMembershipModel(
      id: (json['id'] ?? '').toString(),
      personId: _readFirstNonBlank([json['personId'], personMap['id']]),
      unitId: _readFirstNonBlank([json['unitId'], unitMap['id']]),
      affiliation: _readFirstNonBlank([json['affiliation'], 'VISITOR']),
      fullName: _readOptionalFirstNonBlank([
        personMap['fullName'],
        json['fullName'],
        personMap['name'],
        personMap['username'],
        json['username'],
        personMap['nickname'],
        json['nickname'],
      ]),
      unitConfirmationDate: json['unitConfirmationDate']?.toString(),
      userConfirmationDate: json['userConfirmationDate']?.toString(),
    );
  }

  final String id;
  final String personId;
  final String unitId;
  final String affiliation;
  final String? fullName;
  final String? unitConfirmationDate;
  final String? userConfirmationDate;

  PendingUnitMembershipEntity toEntity() => PendingUnitMembershipEntity(
    id: id,
    personId: personId,
    unitId: unitId,
    affiliation: affiliation,
    fullName: fullName,
    unitConfirmationDate: unitConfirmationDate,
    userConfirmationDate: userConfirmationDate,
  );

  static String _readFirstNonBlank(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String? _readOptionalFirstNonBlank(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}
