import 'package:client/core/config/theme/app_colors.dart';
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
    final initials = _userInitials(user);

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
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE8F0FE),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _userInitials(UserEntity? user) {
  final rawName =
      [user?.fullName?.trim(), user?.nickname?.trim(), user?.username.trim()]
          .whereType<String>()
          .firstWhere((value) => value.isNotEmpty, orElse: () => 'Usuario');

  final parts = rawName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  return parts.isEmpty
      ? 'U'
      : parts.map((part) => part[0].toUpperCase()).join();
}
