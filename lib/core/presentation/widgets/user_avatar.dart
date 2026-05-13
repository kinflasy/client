import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    required this.radius,
    this.profileImageId,
  });

  final String displayName;
  final double radius;
  final String? profileImageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = _UserAvatarFallback(
      displayName: displayName,
      radius: radius,
    );
    final imageId = profileImageId?.trim();

    if (imageId == null || imageId.isEmpty) {
      return fallback;
    }

    final resolvedUrl = ref.watch(mediaImageUrlProvider(imageId));
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: resolvedUrl.when(
        data: (url) => ClipOval(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return fallback;
            },
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        ),
        loading: () => fallback,
        error: (_, _) => fallback,
      ),
    );
  }
}

class _UserAvatarFallback extends StatelessWidget {
  const _UserAvatarFallback({required this.displayName, required this.radius});

  final String displayName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8F0FE),
      child: Text(
        _initials(displayName),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: radius * 0.58,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) return 'U';
  return parts.map((part) => part[0].toUpperCase()).join();
}
