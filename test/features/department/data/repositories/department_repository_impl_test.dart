import 'package:client/core/errors/failure.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/data/models/role_request_model.dart';
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
                'phone': '(85) 99999-0000',
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
          expect(participants.first.phone, '(85) 99999-0000');
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

  group('DepartmentRepositoryImpl.updateParticipantRole', () {
    test('sends payload and returns unit on success', () async {
      when(
        () => api.updateParticipantRole('dep-1', any()),
      ).thenAnswer((_) async => <String, dynamic>{});

      final result = await repository.updateParticipantRole(
        'dep-1',
        const IntegrationRequestModel(
          membershipId: 'membership-1',
          type: IntegrationType.leader,
        ),
      );

      expect(result.isRight(), isTrue);
      expect(
        verify(
          () => api.updateParticipantRole('dep-1', captureAny()),
        ).captured.single,
        {'membershipId': 'membership-1', 'type': 'LEADER'},
      );
    });

    test('maps not found into NotFoundFailure', () async {
      when(() => api.updateParticipantRole('dep-1', any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/integrants'),
          response: Response(
            requestOptions: RequestOptions(path: '/integrants'),
            statusCode: 404,
          ),
        ),
      );

      final result = await repository.updateParticipantRole(
        'dep-1',
        const IntegrationRequestModel(membershipId: 'membership-1'),
      );

      result.match(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('expected failure'),
      );
    });
  });

  group('DepartmentRepositoryImpl.removeParticipant', () {
    test('sends payload and returns unit on success', () async {
      when(
        () => api.removeParticipant('dep-1', any()),
      ).thenAnswer((_) async {});

      final result = await repository.removeParticipant(
        'dep-1',
        const IntegrationRequestModel(membershipId: 'membership-1'),
      );

      expect(result.isRight(), isTrue);
      expect(
        verify(
          () => api.removeParticipant('dep-1', captureAny()),
        ).captured.single,
        {'membershipId': 'membership-1', 'type': 'INTEGRANT'},
      );
    });

    test(
      'maps forbidden into ValidationFailure with backend message',
      () async {
        when(() => api.removeParticipant('dep-1', any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/integrants'),
            response: Response(
              requestOptions: RequestOptions(path: '/integrants'),
              statusCode: 403,
              data: {'message': 'Sem permissão.'},
            ),
          ),
        );

        final result = await repository.removeParticipant(
          'dep-1',
          const IntegrationRequestModel(membershipId: 'membership-1'),
        );

        result.match((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Sem permissão.');
        }, (_) => fail('expected failure'));
      },
    );
  });

  group('DepartmentRepositoryImpl roles', () {
    test('returns role entities on success', () async {
      when(() => api.getRoles()).thenAnswer(
        (_) async => [
          {'id': 'role-1', 'name': 'Vocal', 'slug': 'vocal'},
        ],
      );

      final result = await repository.getRoles();

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (roles) {
        expect(roles, hasLength(1));
        expect(roles.single.id, 'role-1');
        expect(roles.single.name, 'Vocal');
        expect(roles.single.slug, 'vocal');
      });
    });

    test('creates role with request payload', () async {
      when(() => api.createRole(any())).thenAnswer(
        (_) async => {'id': 'role-1', 'name': 'Vocal', 'slug': 'vocal'},
      );

      final result = await repository.createRole(
        const RoleRequestModel(name: 'Vocal'),
      );

      expect(result.isRight(), isTrue);
      expect(verify(() => api.createRole(captureAny())).captured.single, {
        'name': 'Vocal',
      });
    });

    test('maps conflict into ValidationFailure with backend message', () async {
      when(() => api.createRole(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/core/roles'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/core/roles'),
            statusCode: 409,
            data: {'message': 'Papel já existe.'},
          ),
        ),
      );

      final result = await repository.createRole(
        const RoleRequestModel(name: 'Vocal'),
      );

      result.match((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Papel já existe.');
      }, (_) => fail('expected failure'));
    });
  });

  group('DepartmentRepositoryImpl lineups', () {
    test('returns lineup entities with valid nested items', () async {
      when(() => api.getDepartmentLineups('dep-1')).thenAnswer(
        (_) async => [
          {
            'id': 'lineup-1',
            'name': 'Culto',
            'items': [
              {
                'id': 'item-1',
                'lineupId': 'lineup-1',
                'description': 'Vocal principal',
                'role': {'id': 'role-1', 'name': 'Vocal', 'slug': 'vocal'},
              },
              {'id': 'item-invalid', 'description': 'Sem papel'},
            ],
          },
        ],
      );

      final result = await repository.getDepartmentLineups('dep-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (lineups) {
        expect(lineups, hasLength(1));
        expect(lineups.single.id, 'lineup-1');
        expect(lineups.single.name, 'Culto');
        expect(lineups.single.items, hasLength(1));
        expect(lineups.single.items!.single.roleId, 'role-1');
        expect(lineups.single.items!.single.role!.name, 'Vocal');
      });
    });

    test('creates department lineup with request payload', () async {
      when(
        () => api.createDepartmentLineup('dep-1', any()),
      ).thenAnswer((_) async => {'id': 'lineup-1', 'name': 'Culto'});

      final result = await repository.createDepartmentLineup(
        'dep-1',
        const LineupRequestModel(name: 'Culto'),
      );

      expect(result.isRight(), isTrue);
      expect(
        verify(
          () => api.createDepartmentLineup('dep-1', captureAny()),
        ).captured.single,
        {'name': 'Culto'},
      );
    });

    test(
      'creates department lineup from wrapped department lineup payload',
      () async {
        when(() => api.createDepartmentLineup('dep-1', any())).thenAnswer(
          (_) async => {
            'departmentLineup': {'id': 'lineup-1', 'name': 'Culto'},
          },
        );

        final result = await repository.createDepartmentLineup(
          'dep-1',
          const LineupRequestModel(name: 'Culto'),
        );

        expect(result.isRight(), isTrue);
        result.match((_) => fail('expected success'), (lineup) {
          expect(lineup.id, 'lineup-1');
          expect(lineup.name, 'Culto');
        });
      },
    );

    test('updates lineup and fetches detail when response is empty', () async {
      when(
        () => api.updateLineup('lineup-1', any()),
      ).thenAnswer((_) async => <String, dynamic>{});
      when(
        () => api.getLineupById('lineup-1'),
      ).thenAnswer((_) async => {'id': 'lineup-1', 'name': 'Culto atualizado'});

      final result = await repository.updateLineup(
        'lineup-1',
        const LineupRequestModel(name: 'Culto atualizado'),
      );

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected success'),
        (lineup) => expect(lineup.name, 'Culto atualizado'),
      );
      verify(() => api.getLineupById('lineup-1')).called(1);
    });

    test('maps lineup not found into NotFoundFailure', () async {
      when(() => api.getLineupById('lineup-1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/lineups/lineup-1'),
          response: Response(
            requestOptions: RequestOptions(path: '/lineups/lineup-1'),
            statusCode: 404,
            data: {'message': 'Formação não encontrada.'},
          ),
        ),
      );

      final result = await repository.getLineupById('lineup-1');

      result.match((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Formação não encontrada.');
      }, (_) => fail('expected failure'));
    });

    test(
      'maps forbidden into ValidationFailure with backend message',
      () async {
        when(() => api.deleteLineup('lineup-1')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/lineups/lineup-1'),
            response: Response(
              requestOptions: RequestOptions(path: '/lineups/lineup-1'),
              statusCode: 403,
              data: {'message': 'Sem permissão para remover formação.'},
            ),
          ),
        );

        final result = await repository.deleteLineup('lineup-1');

        result.match((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Sem permissão para remover formação.');
        }, (_) => fail('expected failure'));
      },
    );
  });

  group('DepartmentRepositoryImpl lineup items', () {
    test(
      'returns items with roleId or nested role and discards invalid items',
      () async {
        when(() => api.getLineupItems('lineup-1')).thenAnswer(
          (_) async => [
            {
              'id': 'item-1',
              'lineupId': 'lineup-1',
              'roleId': 'role-1',
              'description': 'Vocal principal',
            },
            {
              'id': 'item-2',
              'lineupId': 'lineup-1',
              'description': 'Violão',
              'role': {
                'id': 'role-2',
                'name': 'Instrumentista',
                'slug': 'inst',
              },
            },
            {'id': 'item-invalid', 'lineupId': 'lineup-1'},
          ],
        );

        final result = await repository.getLineupItems('lineup-1');

        expect(result.isRight(), isTrue);
        result.match((_) => fail('expected success'), (items) {
          expect(items, hasLength(2));
          expect(items.first.roleId, 'role-1');
          expect(items.first.role, isNull);
          expect(items.last.roleId, 'role-2');
          expect(items.last.role!.name, 'Instrumentista');
        });
      },
    );

    test('creates item with request payload', () async {
      when(() => api.createLineupItem('lineup-1', any())).thenAnswer(
        (_) async => {
          'id': 'item-1',
          'lineupId': 'lineup-1',
          'roleId': 'role-1',
          'description': 'Vocal principal',
        },
      );

      final result = await repository.createLineupItem(
        'lineup-1',
        const LineupItemRequestModel(
          roleId: 'role-1',
          description: 'Vocal principal',
        ),
      );

      expect(result.isRight(), isTrue);
      expect(
        verify(
          () => api.createLineupItem('lineup-1', captureAny()),
        ).captured.single,
        {'roleId': 'role-1', 'description': 'Vocal principal'},
      );
    });

    test('updates item with description payload', () async {
      when(() => api.updateLineupItem('item-1', any())).thenAnswer(
        (_) async => {
          'id': 'item-1',
          'lineupId': 'lineup-1',
          'roleId': 'role-1',
          'description': 'Vocal de apoio',
        },
      );

      final result = await repository.updateLineupItem(
        'item-1',
        const LineupItemUpdateRequestModel(description: 'Vocal de apoio'),
      );

      expect(result.isRight(), isTrue);
      expect(
        verify(
          () => api.updateLineupItem('item-1', captureAny()),
        ).captured.single,
        {'description': 'Vocal de apoio'},
      );
    });

    test('maps item not found into NotFoundFailure', () async {
      when(() => api.deleteLineupItem('item-1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/lineups/items/item-1'),
          response: Response(
            requestOptions: RequestOptions(path: '/lineups/items/item-1'),
            statusCode: 404,
          ),
        ),
      );

      final result = await repository.deleteLineupItem('item-1');

      result.match((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Item da formação não encontrado.');
      }, (_) => fail('expected failure'));
    });
  });
}
