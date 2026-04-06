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
        'type': 'MAIN',
        'address': 'Rua A, 10',
        'phone': '(11) 99999-0000',
        'email': 'sede@igreja.dev',
        'logoUrl': 'https://cdn/logo.png',
      },
    );

    final result = await repository.getUnitById('unit-1');

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (unit) {
      expect(unit.id, 'unit-1');
      expect(unit.churchId, 'church-1');
      expect(unit.name, 'Sede');
      expect(unit.type, 'MAIN');
      expect(unit.address, 'Rua A, 10');
      expect(unit.phone, '(11) 99999-0000');
      expect(unit.email, 'sede@igreja.dev');
      expect(unit.logoUrl, 'https://cdn/logo.png');
    });
  });

  test('returns units by church id on success', () async {
    when(() => api.getUnitsByChurchId('church-1')).thenAnswer(
      (_) async => [
        {
          'id': 'unit-1',
          'churchId': 'church-1',
          'name': 'Sede',
          'type': 'MAIN',
        },
        {
          'id': 'unit-2',
          'churchId': 'church-1',
          'name': 'Filial',
          'type': 'BRANCH',
        },
      ],
    );

    final result = await repository.getUnitsByChurchId('church-1');

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (units) {
      expect(units, hasLength(2));
      expect(units.first.type, 'MAIN');
      expect(units.last.type, 'BRANCH');
    });
  });

  test('returns empty list when church has no units', () async {
    when(() => api.getUnitsByChurchId('church-1')).thenAnswer((_) async => []);

    final result = await repository.getUnitsByChurchId('church-1');

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected success'),
      (units) => expect(units, isEmpty),
    );
  });

  test('maps list lookup errors into NetworkFailure', () async {
    when(() => api.getUnitsByChurchId('church-1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(
          path: '/v1/core/churches/church-1/units',
        ),
        message: 'timeout',
      ),
    );

    final result = await repository.getUnitsByChurchId('church-1');

    expect(result.isLeft(), isTrue);
    result.match((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'timeout');
    }, (_) => fail('expected failure'));
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
