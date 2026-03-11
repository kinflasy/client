import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String fullName,
    required String username,
    required String email,
    String? nickname,
    String? phone,
    @JsonKey(name: 'birthDate') String? birthDate,
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
      );
}