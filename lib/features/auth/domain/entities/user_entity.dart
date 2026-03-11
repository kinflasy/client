import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.nickname,
  });

  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? nickname;

  @override
  List<Object?> get props => [id, username, email];
}