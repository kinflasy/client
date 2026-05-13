import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String username,
    String? fullName,
    String? email,
    String? nickname,
    String? phone,
    String? gender,
    @JsonKey(name: 'birthDate') String? birthDate,
    String? profileImageId,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  UserEntity toEntity() => UserEntity(
    id: id,
    fullName: fullName,
    username: username,
    email: email,
    nickname: nickname,
    phone: phone,
    gender: gender,
    birthDate: birthDate != null ? DateTime.tryParse(birthDate!) : null,
    profileImageId: profileImageId,
  );
}
