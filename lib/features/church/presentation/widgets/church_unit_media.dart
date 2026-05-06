import 'dart:io';

import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChurchUnitAvatar extends ConsumerWidget {
  const ChurchUnitAvatar({
    super.key,
    required this.displayName,
    required this.radius,
    this.imageId,
    this.imageUrl,
    this.borderColor,
    this.borderWidth = 0,
    this.textStyle,
  });

  final String displayName;
  final double radius;
  final String? imageId;
  final String? imageUrl;
  final Color? borderColor;
  final double borderWidth;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUrl = _resolvedImageUrl(ref, imageId, imageUrl);
    final fallback = _AvatarFallback(
      displayName: displayName,
      radius: radius,
      textStyle: textStyle,
    );

    Widget child = resolvedUrl.when(
      data: (url) => ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: _NetworkImageFill(url: url, fallback: fallback),
        ),
      ),
      loading: () => fallback,
      error: (_, _) => fallback,
    );

    if (borderWidth > 0 && borderColor != null) {
      final outerDiameter = (radius + borderWidth) * 2;
      return SizedBox(
        width: outerDiameter,
        height: outerDiameter,
        child: DecoratedBox(
          decoration: BoxDecoration(color: borderColor, shape: BoxShape.circle),
          child: Center(child: child),
        ),
      );
    }

    return SizedBox(width: radius * 2, height: radius * 2, child: child);
  }
}

class ChurchUnitCover extends ConsumerWidget {
  const ChurchUnitCover({
    super.key,
    required this.height,
    this.imageId,
    this.imageUrl,
    this.borderRadius = BorderRadius.zero,
    this.fallback,
  });

  final double height;
  final String? imageId;
  final String? imageUrl;
  final BorderRadius borderRadius;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUrl = _resolvedImageUrl(ref, imageId, imageUrl);
    final fallbackWidget =
        fallback ??
        Container(
          color: const Color(0xFFE8F0FE),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
        );

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: resolvedUrl.when(
          data: (url) => _NetworkImageFill(url: url, fallback: fallbackWidget),
          loading: () => fallbackWidget,
          error: (_, _) => fallbackWidget,
        ),
      ),
    );
  }
}

class UnitImagePreview extends ConsumerWidget {
  const UnitImagePreview({
    super.key,
    required this.height,
    required this.isRound,
    this.imageId,
    this.imageUrl,
    this.preview,
  });

  final double height;
  final bool isRound;
  final String? imageId;
  final String? imageUrl;
  final File? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderRadius = BorderRadius.circular(isRound ? height / 2 : 8);
    final width = isRound ? height : double.infinity;
    final fallback = Container(
      color: const Color(0xFFE8F0FE),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: AppColors.textSecondary,
      ),
    );

    Widget child;
    if (preview != null) {
      child = Image.file(preview!, fit: BoxFit.cover);
    } else {
      final resolvedUrl = _resolvedImageUrl(ref, imageId, imageUrl);
      child = resolvedUrl.when(
        data: (url) => _NetworkImageFill(url: url, fallback: fallback),
        loading: () => fallback,
        error: (_, _) => fallback,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

AsyncValue<String> _resolvedImageUrl(
  WidgetRef ref,
  String? imageId,
  String? imageUrl,
) {
  final id = imageId?.trim();
  if (id != null && id.isNotEmpty) {
    return ref.watch(mediaImageUrlProvider(id));
  }

  final url = imageUrl?.trim();
  if (url != null && url.isNotEmpty) {
    return AsyncValue.data(url);
  }

  return const AsyncValue.error('', StackTrace.empty);
}

class _NetworkImageFill extends StatelessWidget {
  const _NetworkImageFill({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return fallback;
      },
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.displayName,
    required this.radius,
    this.textStyle,
  });

  final String displayName;
  final double radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8F0FE),
      child: Text(
        churchInitials(displayName),
        style:
            textStyle ??
            TextStyle(
              color: AppColors.primary,
              fontSize: radius * 0.58,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
