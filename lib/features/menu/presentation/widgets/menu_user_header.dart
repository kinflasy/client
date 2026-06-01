import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuUserHeader extends ConsumerWidget {
  const MenuUserHeader({super.key, required this.authState});

  final AsyncValue<UserEntity?> authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (authState) {
      AsyncLoading<UserEntity?>() => const MenuUserHeaderLoading(),
      AsyncError<UserEntity?>() => const MenuUserHeaderContent(user: null),
      AsyncData<UserEntity?>(:final value) => _buildContent(ref, value),
    };
  }

  Widget _buildContent(WidgetRef ref, UserEntity? user) {
    if (user == null) return const MenuUserHeaderContent(user: null);

    final profile = ref.watch(editLoggedUserInitialDataProvider).asData?.value;

    return MenuUserHeaderContent(
      user: user,
      profile: profile?.id == user.id ? profile : null,
    );
  }
}

class MenuUserHeaderContent extends StatelessWidget {
  const MenuUserHeaderContent({super.key, required this.user, this.profile});

  final UserEntity? user;
  final LoggedUserProfileEntity? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final displayName = _displayName(user, profile);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          UserAvatar(
            displayName: displayName,
            radius: 40,
            profileImageId: _profileImageId(user, profile),
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
              color: AppColors.surfaceContainerHigh,
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

String _displayName(UserEntity? user, LoggedUserProfileEntity? profile) {
  return profile?.nickname?.trim().isNotEmpty == true
      ? profile!.nickname!.trim()
      : profile?.fullName.trim().isNotEmpty == true
      ? profile!.fullName.trim()
      : user?.nickname?.trim().isNotEmpty == true
      ? user!.nickname!.trim()
      : user?.fullName?.trim().isNotEmpty == true
      ? user!.fullName!.trim()
      : user?.username.trim().isNotEmpty == true
      ? user!.username.trim()
      : 'Usuário';
}

String? _profileImageId(UserEntity? user, LoggedUserProfileEntity? profile) {
  final profileImageId = profile?.profileImageId?.trim();
  if (profileImageId != null && profileImageId.isNotEmpty) {
    return profileImageId;
  }

  final authImageId = user?.profileImageId?.trim();
  return authImageId == null || authImageId.isEmpty ? null : authImageId;
}
