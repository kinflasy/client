// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String,
  username: json['username'] as String,
  fullName: json['fullName'] as String?,
  email: json['email'] as String?,
  nickname: json['nickname'] as String?,
  phone: json['phone'] as String?,
  gender: json['gender'] as String?,
  birthDate: json['birthDate'] as String?,
  profileImageId: json['profileImageId'] as String?,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
      'email': instance.email,
      'nickname': instance.nickname,
      'phone': instance.phone,
      'gender': instance.gender,
      'birthDate': instance.birthDate,
      'profileImageId': instance.profileImageId,
    };
