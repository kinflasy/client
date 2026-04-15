import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuUserHeader extends StatelessWidget {
  const MenuUserHeader({super.key, required this.authState});

  final AsyncValue<UserEntity?> authState;

  @override
  Widget build(BuildContext context) {
    return switch (authState) {
      AsyncLoading<UserEntity?>() => const MenuUserHeaderLoading(),
      AsyncError<UserEntity?>() => const MenuUserHeaderContent(user: null),
      AsyncData<UserEntity?>(:final value) => MenuUserHeaderContent(
        user: value,
      ),
    };
  }
}

class MenuUserHeaderContent extends StatelessWidget {
  const MenuUserHeaderContent({super.key, required this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final displayName = _displayName(user);
    final initials = _userInitials(user);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initials,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class MenuUserHeaderLoading extends StatelessWidget {
  const MenuUserHeaderLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 144,
            height: 20,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

String _displayName(UserEntity? user) {
  return user?.nickname?.trim().isNotEmpty == true
      ? user!.nickname!.trim()
      : user?.fullName?.trim().isNotEmpty == true
      ? user!.fullName!.trim()
      : user?.username.trim().isNotEmpty == true
      ? user!.username.trim()
      : 'UsuÃ¡rio';
}

String _userInitials(UserEntity? user) {
  final rawName = _displayName(user);
  final parts = rawName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  return parts.isEmpty
      ? 'U'
      : parts.map((part) => part[0].toUpperCase()).join();
}
