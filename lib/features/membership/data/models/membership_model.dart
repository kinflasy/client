import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';

part 'membership_model.freezed.dart';
part 'membership_model.g.dart';

@freezed
abstract class MembershipModel with _$MembershipModel {
  const factory MembershipModel({
    required String id,
    required String unitId,
  }) = _MembershipModel;

  factory MembershipModel.fromJson(Map<String, dynamic> json) =>
      _$MembershipModelFromJson(json);
}

extension MembershipModelX on MembershipModel {
  MembershipEntity toEntity() => MembershipEntity(
        id: id,
        unitId: unitId,
      );
}