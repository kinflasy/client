import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/datasources/church_unit_api.dart';
import 'package:client/features/church/data/repositories/church_unit_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitApi extends Mock implements ChurchUnitApi {}

void main() {
  late ChurchUnitRepositoryImpl repository;
  late _MockChurchUnitApi api;

  setUp(() {
    api = _MockChurchUnitApi();
    repository = ChurchUnitRepositoryImpl(api);
  });

  test('returns unit entity on success', () async {
    when(() => api.getUnitById('unit-1')).thenAnswer(
      (_) async => {
        'id': 'unit-1',
        'churchId': 'church-1',
        'name': 'Sede',
      },
    );

    final result = await repository.getUnitById('unit-1');

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected success'),
      (unit) {
        expect(unit.id, 'unit-1');
        expect(unit.churchId, 'church-1');
        expect(unit.name, 'Sede');
      },
    );
  });

  test('maps 404 into NotFoundFailure', () async {
    when(() => api.getUnitById('missing')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/v1/core/church/units/missing'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/core/church/units/missing'),
          statusCode: 404,
        ),
      ),
    );

    final result = await repository.getUnitById('missing');

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<NotFoundFailure>()),
      (_) => fail('expected failure'),
    );
  });
}
