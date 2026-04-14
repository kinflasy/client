import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit_member_model.freezed.dart';
part 'unit_member_model.g.dart';

@freezed
abstract class UnitMemberModel with _$UnitMemberModel {
  const factory UnitMemberModel({
    required String id,
    required String unitId,
    required UnitMemberPersonModel person,
    required String affiliation,
  }) = _UnitMemberModel;

  factory UnitMemberModel.fromJson(Map<String, dynamic> json) =>
      _$UnitMemberModelFromJson(json);
}

@freezed
abstract class UnitMemberPersonModel with _$UnitMemberPersonModel {
  const factory UnitMemberPersonModel({
    required String id,
    required String fullName,
    String? nickname,
    required String gender,
    String? birthDate,
    String? phone,
    String? addressId,
  }) = _UnitMemberPersonModel;

  factory UnitMemberPersonModel.fromJson(Map<String, dynamic> json) =>
      _$UnitMemberPersonModelFromJson(json);
}

extension UnitMemberModelX on UnitMemberModel {
  UnitMemberEntity toEntity() => UnitMemberEntity(
    membershipId: id,
    personId: person.id,
    fullName: person.fullName,
    nickname: person.nickname,
    affiliation: affiliation,
    gender: person.gender,
    birthDate: person.birthDate != null
        ? DateTime.tryParse(person.birthDate!)
        : null,
    phone: person.phone,
    addressId: person.addressId,
  );
}
