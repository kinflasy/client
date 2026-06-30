import 'package:equatable/equatable.dart';

class MembershipEntity extends Equatable {
  const MembershipEntity({
    required this.id,
    required this.unitId,
    required this.affiliation,
    this.unitName,
    this.unitLogoUrl,
    this.unitProfileImageId,
  });

  final String id;
  final String unitId;
  final String affiliation;
  final String? unitName;
  final String? unitLogoUrl;
  final String? unitProfileImageId;

  @override
  List<Object?> get props => [
    id,
    unitId,
    affiliation,
    unitName,
    unitLogoUrl,
    unitProfileImageId,
  ];
}
