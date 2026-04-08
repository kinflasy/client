import 'package:client/core/errors/failure.dart';
import 'package:client/core/fga/fga_config.dart';
import 'package:client/core/fga/fga_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late FgaService service;

  setUp(() {
    dio = _MockDio();
    service = FgaService(dio, () async => null);
  });

  test('returns false when there is no authenticated user', () async {
    final allowed = await service.check(object: 'unit:1', relation: 'admin');

    expect(allowed, isFalse);
    verifyNever(
      () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    );
  });

  test('returns allowed status from FGA', () async {
    service = FgaService(dio, () async => 'user-1');
    when(
      () => dio.post<Map<String, dynamic>>(
        FgaConfig.checkUrl,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: FgaConfig.checkUrl),
        data: {'allowed': true},
      ),
    );

    final allowed = await service.check(object: 'unit:1', relation: 'admin');

    expect(allowed, isTrue);
    verify(
      () => dio.post<Map<String, dynamic>>(
        FgaConfig.checkUrl,
        data: {
          'authorization_model_id': FgaConfig.modelId,
          'tuple_key': {
            'user': 'user:user-1',
            'relation': 'admin',
            'object': 'unit:1',
          },
        },
      ),
    ).called(1);
  });

  test('throws network failure when dio request fails', () async {
    service = FgaService(dio, () async => 'user-1');
    when(
      () => dio.post<Map<String, dynamic>>(
        FgaConfig.checkUrl,
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: FgaConfig.checkUrl),
        message: 'timeout',
      ),
    );

    await expectLater(
      service.check(object: 'unit:1', relation: 'admin'),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
