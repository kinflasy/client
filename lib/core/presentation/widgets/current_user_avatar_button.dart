import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentUserAvatarButton extends ConsumerWidget {
  const CurrentUserAvatarButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.asData?.value;
    final displayName = _userDisplayName(user);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            child: UserAvatar(
              displayName: displayName,
              radius: 16,
              profileImageId: user?.profileImageId,
            ),
          ),
        ),
      ),
    );
  }
}

String _userDisplayName(UserEntity? user) {
  return [user?.fullName?.trim(), user?.nickname?.trim(), user?.username.trim()]
      .whereType<String>()
      .firstWhere((value) => value.isNotEmpty, orElse: () => 'Usuário');
}
