import 'package:client/core/errors/failure.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
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
    test(
      'returns participants from nested integration payload on success',
      () async {
        when(() => api.getParticipants('dep-1')).thenAnswer(
          (_) async => [
            {
              'id': 'integration-1',
              'department': {'id': 'dep-1'},
              'membership': {
                'id': 'membership-1',
                'unitId': 'unit-1',
                'affiliation': 'MEMBER',
                'person': {
                  'id': 'person-1',
                  'nickname': 'Maria',
                  'username': 'maria.silva',
                  'profileImageId': 'profile-image-1',
                  'gender': 'FEMALE',
                  'birthDate': '1990-05-12T00:00:00.000Z',
                  'age': 34,
                },
              },
              'type': 'LEADER',
            },
            {
              'id': 'integration-2',
              'department': {'id': 'dep-1'},
              'membership': {
                'id': 'membership-2',
                'unitId': 'unit-1',
                'affiliation': 'CONGREGATED',
                'person': {
                  'id': 'person-2',
                  'username': 'joao.souza',
                  'gender': 'MALE',
                  'birthDate': '',
                },
              },
              'type': 'OBSERVER',
            },
          ],
        );

        final result = await repository.getParticipants('dep-1');

        expect(result.isRight(), isTrue);
        result.match((_) => fail('expected success'), (participants) {
          expect(participants, hasLength(2));
          expect(participants.first.membershipId, 'membership-1');
          expect(participants.first.integrationType, IntegrationType.leader);
          expect(participants.first.nickname, 'Maria');
          expect(participants.first.username, 'maria.silva');
          expect(participants.first.profileImageId, 'profile-image-1');
          expect(participants.first.displayName, 'Maria');
          expect(
            participants.first.birthDate,
            DateTime.parse('1990-05-12T00:00:00.000Z'),
          );
          expect(participants.first.age, 34);
          expect(participants.last.personId, 'person-2');
          expect(participants.last.membershipId, 'membership-2');
          expect(participants.last.integrationType, IntegrationType.observer);
          expect(participants.last.nickname, isNull);
          expect(participants.last.username, 'joao.souza');
          expect(participants.last.displayName, 'joao.souza');
          expect(participants.last.birthDate, isNull);
          expect(participants.last.age, isNull);
        });
      },
    );

    test('maps assistant and unknown integration types safely', () async {
      when(() => api.getParticipants('dep-1')).thenAnswer(
        (_) async => [
          {
            'membership': {
              'id': 'membership-1',
              'affiliation': 'MEMBER',
              'person': {'id': 'person-1', 'gender': 'FEMALE'},
            },
            'type': 'ASSISTANT',
          },
          {
            'membership': {
              'id': 'membership-2',
              'affiliation': 'MEMBER',
              'person': {'id': 'person-2', 'gender': 'MALE'},
            },
            'type': 'UNKNOWN',
          },
        ],
      );

      final result = await repository.getParticipants('dep-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (participants) {
        expect(participants, hasLength(2));
        expect(participants.first.integrationType, IntegrationType.assistant);
        expect(participants.last.integrationType, IntegrationType.observer);
      });
    });

    test(
      'uses neutral display name when nickname and username are absent',
      () async {
        when(() => api.getParticipants('dep-1')).thenAnswer(
          (_) async => [
            {
              'id': 'integration-1',
              'membership': {
                'id': 'membership-1',
                'affiliation': 'MEMBER',
                'person': {'id': 'person-1', 'gender': 'FEMALE'},
              },
              'type': 'LEADER',
            },
          ],
        );

        final result = await repository.getParticipants('dep-1');

        expect(result.isRight(), isTrue);
        result.match((_) => fail('expected success'), (participants) {
          expect(participants, hasLength(1));
          expect(participants.first.nickname, isNull);
          expect(participants.first.username, isNull);
          expect(participants.first.displayName, 'Participante');
        });
      },
    );

    test('keeps birthDate when age is absent', () async {
      when(() => api.getParticipants('dep-1')).thenAnswer(
        (_) async => [
          {
            'id': 'integration-1',
            'membership': {
              'id': 'membership-1',
              'affiliation': 'MEMBER',
              'person': {
                'id': 'person-1',
                'nickname': 'Maria',
                'gender': 'FEMALE',
                'birthDate': '1990-05-12',
              },
            },
            'type': 'LEADER',
          },
        ],
      );

      final result = await repository.getParticipants('dep-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (participants) {
        expect(participants, hasLength(1));
        expect(participants.first.age, isNull);
        expect(participants.first.birthDate, DateTime.parse('1990-05-12'));
      });
    });

    test('discards items without membership person id', () async {
      when(() => api.getParticipants('dep-1')).thenAnswer(
        (_) async => [
          {
            'id': 'integration-1',
            'membership': {
              'id': 'membership-1',
              'affiliation': 'MEMBER',
              'person': {'nickname': 'Maria', 'gender': 'FEMALE'},
            },
            'type': 'LEADER',
          },
        ],
      );

      final result = await repository.getParticipants('dep-1');

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected success'),
        (participants) => expect(participants, isEmpty),
      );
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

  group('DepartmentRepositoryImpl.addParticipant', () {
    test('sends payload and returns unit on success', () async {
      when(
        () => api.addParticipant('dep-1', any()),
      ).thenAnswer((_) async => <String, dynamic>{});

      final result = await repository.addParticipant(
        'dep-1',
        const IntegrationRequestModel(membershipId: 'membership-1'),
      );

      expect(result.isRight(), isTrue);
      final captured = verify(
        () => api.addParticipant('dep-1', captureAny()),
      ).captured.single;
      expect(captured, {'membershipId': 'membership-1', 'type': 'INTEGRANT'});
    });

    test('maps dio failure into NetworkFailure', () async {
      when(() => api.addParticipant('dep-1', any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/core/church/unit/departments/dep-1/integrants',
          ),
          message: 'offline',
        ),
      );

      final result = await repository.addParticipant(
        'dep-1',
        const IntegrationRequestModel(membershipId: 'membership-1'),
      );

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'offline');
      }, (_) => fail('expected failure'));
    });

    test('maps conflict into ValidationFailure with backend message', () async {
      when(() => api.addParticipant('dep-1', any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/core/church/unit/departments/dep-1/integrants',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/v1/core/church/unit/departments/dep-1/integrants',
            ),
            statusCode: 409,
            data: {'message': 'Participante já vinculado.'},
          ),
        ),
      );

      final result = await repository.addParticipant(
        'dep-1',
        const IntegrationRequestModel(membershipId: 'membership-1'),
      );

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Participante já vinculado.');
      }, (_) => fail('expected failure'));
    });
  });
}
