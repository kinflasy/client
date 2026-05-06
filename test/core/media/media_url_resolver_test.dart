import 'package:client/core/media/media_url_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late DateTime now;

  setUp(() {
    dio = _MockDio();
    now = DateTime(2026, 5, 6, 12);
  });

  MediaUrlResolver buildResolver() {
    return MediaUrlResolver(
      dio,
      now: () => now,
      ttl: const Duration(seconds: 60),
      refreshMargin: const Duration(seconds: 10),
    );
  }

  test('fetches a signed media URL by image id', () async {
    when(() => dio.get<dynamic>('/v1/media/image-1')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/media/image-1'),
        data: {'url': 'https://cdn.example/image-1.png'},
      ),
    );

    final resolver = buildResolver();

    await expectLater(
      resolver.resolveImageUrl('image-1'),
      completion('https://cdn.example/image-1.png'),
    );
    verify(() => dio.get<dynamic>('/v1/media/image-1')).called(1);
  });

  test('reuses cached URL while it is not close to expiration', () async {
    when(() => dio.get<dynamic>('/v1/media/image-1')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/media/image-1'),
        data: 'https://cdn.example/image-1.png',
      ),
    );

    final resolver = buildResolver();

    expect(await resolver.resolveImageUrl('image-1'), contains('image-1.png'));
    now = now.add(const Duration(seconds: 40));
    expect(await resolver.resolveImageUrl('image-1'), contains('image-1.png'));

    verify(() => dio.get<dynamic>('/v1/media/image-1')).called(1);
  });

  test('refreshes cached URL when close to expiration', () async {
    when(() => dio.get<dynamic>('/v1/media/image-1')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/media/image-1'),
        data: {'url': 'https://cdn.example/image-1-v1.png'},
      ),
    );

    final resolver = buildResolver();

    expect(await resolver.resolveImageUrl('image-1'), contains('v1'));
    now = now.add(const Duration(seconds: 51));

    when(() => dio.get<dynamic>('/v1/media/image-1')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/media/image-1'),
        data: {'url': 'https://cdn.example/image-1-v2.png'},
      ),
    );

    expect(await resolver.resolveImageUrl('image-1'), contains('v2'));
    verify(() => dio.get<dynamic>('/v1/media/image-1')).called(2);
  });
}
