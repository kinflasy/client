import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';

part 'membership_model.freezed.dart';
part 'membership_model.g.dart';

@freezed
abstract class MembershipModel with _$MembershipModel {
  const factory MembershipModel({
    required String id,
    required String unitId,
    @Default('VISITOR') String affiliation,
    String? unitName,
    String? unitLogoUrl,
    String? unitProfileImageId,
  }) = _MembershipModel;

  factory MembershipModel.fromJson(Map<String, dynamic> json) =>
      _$MembershipModelFromJson(json);
}

extension MembershipModelX on MembershipModel {
  MembershipEntity toEntity() => MembershipEntity(
    id: id,
    unitId: unitId,
    affiliation: affiliation,
    unitName: unitName,
    unitLogoUrl: unitLogoUrl,
    unitProfileImageId: unitProfileImageId,
  );
}

class ActiveMembershipModel {
  const ActiveMembershipModel({
    required this.id,
    required this.unitId,
    required this.personId,
    required this.affiliation,
    this.entryDate,
    this.unitName,
    this.unitLogoUrl,
    this.unitProfileImageId,
  });

  factory ActiveMembershipModel.fromJson(Map<String, dynamic> json) {
    return ActiveMembershipModel(
      id: (json['id'] ?? '').toString(),
      unitId: (json['unitId'] ?? '').toString(),
      personId: (json['personId'] ?? '').toString(),
      affiliation: (json['affiliation'] ?? '').toString(),
      entryDate: json['entryDate']?.toString(),
      unitName: json['unitName']?.toString(),
      unitLogoUrl: json['unitLogoUrl']?.toString(),
      unitProfileImageId: json['unitProfileImageId']?.toString(),
    );
  }

  final String id;
  final String unitId;
  final String personId;
  final String affiliation;
  final String? entryDate;
  final String? unitName;
  final String? unitLogoUrl;
  final String? unitProfileImageId;

  MembershipEntity toEntity() => MembershipEntity(
    id: id,
    unitId: unitId,
    affiliation: affiliation,
    unitName: unitName,
    unitLogoUrl: unitLogoUrl,
    unitProfileImageId: unitProfileImageId,
  );
}
