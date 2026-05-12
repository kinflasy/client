import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventImage extends ConsumerWidget {
  const EventImage({
    super.key,
    required this.imageId,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final String imageId;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUrl = ref.watch(mediaImageUrlProvider(imageId));

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: resolvedUrl.when(
          data: (url) => Image.network(
            url,
            key: const Key('event-image-network'),
            width: double.infinity,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const _EventImageFallback();
            },
            errorBuilder: (context, error, stackTrace) =>
                const _EventImageFallback(),
          ),
          loading: () => const _EventImageFallback(),
          error: (error, stackTrace) => const _EventImageFallback(),
        ),
      ),
    );
  }
}

class _EventImageFallback extends StatelessWidget {
  const _EventImageFallback();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      height: 140,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 36,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
