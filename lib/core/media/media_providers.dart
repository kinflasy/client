import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'media_url_resolver.dart';

final mediaUrlResolverProvider = Provider<MediaUrlResolver>(
  (ref) => MediaUrlResolver(ref.watch(dioClientProvider)),
);

final mediaImageUrlProvider = FutureProvider.family<String, String>((
  ref,
  imageId,
) {
  return ref.watch(mediaUrlResolverProvider).resolveImageUrl(imageId);
});
