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
  }) = _MembershipModel;

  factory MembershipModel.fromJson(Map<String, dynamic> json) =>
      _$MembershipModelFromJson(json);
}

extension MembershipModelX on MembershipModel {
  MembershipEntity toEntity() =>
      MembershipEntity(id: id, unitId: unitId, affiliation: affiliation);
}

class ActiveMembershipModel {
  const ActiveMembershipModel({
    required this.id,
    required this.unitId,
    required this.personId,
    required this.affiliation,
    this.entryDate,
  });

  factory ActiveMembershipModel.fromJson(Map<String, dynamic> json) {
    return ActiveMembershipModel(
      id: (json['id'] ?? '').toString(),
      unitId: (json['unitId'] ?? '').toString(),
      personId: (json['personId'] ?? '').toString(),
      affiliation: (json['affiliation'] ?? '').toString(),
      entryDate: json['entryDate']?.toString(),
    );
  }

  final String id;
  final String unitId;
  final String personId;
  final String affiliation;
  final String? entryDate;

  MembershipEntity toEntity() =>
      MembershipEntity(id: id, unitId: unitId, affiliation: affiliation);
}
