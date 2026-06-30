import 'package:equatable/equatable.dart';

class ActivationUserEntity extends Equatable {
  const ActivationUserEntity({
    required this.id,
    required this.username,
    this.nickname,
    this.profileImageId,
  });

  final String id;
  final String username;
  final String? nickname;
  final String? profileImageId;

  @override
  List<Object?> get props => [id, username, nickname, profileImageId];
}
