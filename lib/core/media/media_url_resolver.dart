import 'package:dio/dio.dart';

class MediaUrlResolver {
  MediaUrlResolver(
    this._dio, {
    DateTime Function()? now,
    Duration ttl = const Duration(seconds: 60),
    Duration refreshMargin = const Duration(seconds: 10),
  }) : _now = now ?? DateTime.now,
       _ttl = ttl,
       _refreshMargin = refreshMargin;

  final Dio _dio;
  final DateTime Function() _now;
  final Duration _ttl;
  final Duration _refreshMargin;
  final Map<String, _CachedMediaUrl> _cache = {};

  Future<String> resolveImageUrl(String imageId) async {
    final cached = _cache[imageId];
    final now = _now();
    if (cached != null && cached.expiresAt.difference(now) > _refreshMargin) {
      return cached.url;
    }

    final response = await _dio.get<dynamic>('/v1/media/$imageId');
    final url = _extractUrl(response.data).trim();
    if (url.isEmpty) {
      throw StateError('Resposta de midia sem URL.');
    }

    _cache[imageId] = _CachedMediaUrl(url: url, expiresAt: now.add(_ttl));
    return url;
  }

  String _extractUrl(dynamic data) {
    if (data is String) return data;

    if (data is Map) {
      final map = Map<dynamic, dynamic>.from(data);
      for (final key in const [
        'url',
        'downloadUrl',
        'download_url',
        'signedUrl',
        'signed_url',
        'presignedUrl',
        'preSignedUrl',
        'mediaUrl',
      ]) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }

    return '';
  }
}

class _CachedMediaUrl {
  const _CachedMediaUrl({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
