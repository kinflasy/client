import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.nickname,
    this.phone,
    this.gender,
    this.birthDate,
  });

  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String? nickname;
  final String? phone;
  final String? gender;
  final DateTime? birthDate;

  @override
  List<Object?> get props => [id, username, email, fullName, nickname, phone, gender, birthDate];
}
