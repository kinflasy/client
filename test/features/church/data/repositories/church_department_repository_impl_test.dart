import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/data/repositories/department_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentApi extends Mock implements DepartmentApi {}

void main() {
  late DepartmentRepositoryImpl repository;
  late _MockDepartmentApi api;

  setUp(() {
    api = _MockDepartmentApi();
    repository = DepartmentRepositoryImpl(api);
  });

  group('DepartmentRepositoryImpl.getDepartmentsByUnitId', () {
    test('returns department entities on success', () async {
      when(() => api.getDepartmentsByUnitId('unit-1')).thenAnswer(
        (_) async => [
          {
            'id': 'dep-1',
            'name': 'Louvor',
            'slug': 'louvor',
            'type': 'MINISTRY',
          },
          {'id': 'dep-2', 'name': 'Secretaria', 'type': 'ADMINISTRATIVE'},
        ],
      );

      final result = await repository.getDepartmentsByUnitId('unit-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (departments) {
        expect(departments, hasLength(2));
        expect(departments.first.name, 'Louvor');
        expect(departments.first.slug, 'louvor');
        expect(departments.last.type, 'ADMINISTRATIVE');
      });
    });

    test('returns empty list when api has no departments', () async {
      when(() => api.getDepartmentsByUnitId('unit-1')).thenAnswer((_) async => []);

      final result = await repository.getDepartmentsByUnitId('unit-1');

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected success'),
        (departments) => expect(departments, isEmpty),
      );
    });

    test('maps dio failure into NetworkFailure', () async {
      when(() => api.getDepartmentsByUnitId('unit-1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/core/church/units/unit-1/departments',
          ),
          message: 'timeout',
        ),
      );

      final result = await repository.getDepartmentsByUnitId('unit-1');

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'timeout');
      }, (_) => fail('expected failure'));
    });
  });

  group('DepartmentRepositoryImpl.createDepartment', () {
    test('maps validation failures from api', () async {
      const request = DepartmentRequestModel(
        name: 'Recepcao',
        slug: 'recepcao',
        type: 'MINISTRY',
      );

      when(() => api.createDepartment('unit-1', request.toJson())).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/core/church/units/unit-1/departments',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/v1/core/church/units/unit-1/departments',
            ),
            statusCode: 409,
            data: {'message': 'Slug ja usado'},
          ),
        ),
      );

      final result = await repository.createDepartment('unit-1', request);

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Slug ja usado');
      }, (_) => fail('expected failure'));
    });
  });
}
