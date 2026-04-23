import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
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

  group('DepartmentRepositoryImpl.getDepartmentById', () {
    test('returns department detail on success', () async {
      when(() => api.getDepartmentById('dep-1')).thenAnswer(
        (_) async => {
          'id': 'dep-1',
          'name': 'Louvor',
          'slug': 'louvor',
          'type': 'MINISTRY',
        },
      );

      final result = await repository.getDepartmentById('dep-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (department) {
        expect(department.id, 'dep-1');
        expect(department.name, 'Louvor');
        expect(department.slug, 'louvor');
        expect(department.type, 'MINISTRY');
      });
    });

    test('maps dio failure into NetworkFailure', () async {
      when(() => api.getDepartmentById('dep-1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/core/church/unit/departments/dep-1',
          ),
          message: 'timeout',
        ),
      );

      final result = await repository.getDepartmentById('dep-1');

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'timeout');
      }, (_) => fail('expected failure'));
    });
  });

  group('DepartmentRepositoryImpl.getParticipants', () {
    test('returns participants on success', () async {
      when(() => api.getParticipants('dep-1')).thenAnswer(
        (_) async => [
          {
            'personId': 'person-1',
            'fullName': 'Maria Silva',
            'affiliation': 'MEMBER',
            'gender': 'FEMALE',
            'birthDate': '1990-05-12T00:00:00.000Z',
          },
          {
            'personId': 'person-2',
            'fullName': 'Joao Souza',
            'affiliation': 'CONGREGATED',
            'gender': 'MALE',
            'birthDate': '',
          },
        ],
      );

      final result = await repository.getParticipants('dep-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (participants) {
        expect(participants, hasLength(2));
        expect(participants.first.fullName, 'Maria Silva');
        expect(participants.first.birthDate, DateTime.parse('1990-05-12T00:00:00.000Z'));
        expect(participants.last.personId, 'person-2');
        expect(participants.last.birthDate, isNull);
      });
    });

    test('returns empty list when api has no participants', () async {
      when(() => api.getParticipants('dep-1')).thenAnswer((_) async => []);

      final result = await repository.getParticipants('dep-1');

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected success'),
        (participants) => expect(participants, isEmpty),
      );
    });

    test('maps dio failure into NetworkFailure', () async {
      when(() => api.getParticipants('dep-1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/core/church/unit/departments/dep-1/integrants',
          ),
          message: 'offline',
        ),
      );

      final result = await repository.getParticipants('dep-1');

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'offline');
      }, (_) => fail('expected failure'));
    });
  });
}
