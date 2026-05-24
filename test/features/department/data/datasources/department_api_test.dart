import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late DepartmentApi api;

  setUp(() {
    dio = _MockDio();
    api = DepartmentApi(dio);
  });

  test('getDepartmentsByUnitId accepts direct list response', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/units/unit-1/departments'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/unit-1/departments',
        ),
        data: [
          {'id': 'dep-1', 'name': 'Louvor'},
        ],
      ),
    );

    final result = await api.getDepartmentsByUnitId('unit-1');

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'dep-1');
  });

  test('getDepartmentsByUnitId accepts paginated content response', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/units/unit-1/departments'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/unit-1/departments',
        ),
        data: {
          'content': [
            {'id': 'dep-1', 'name': 'Louvor'},
          ],
        },
      ),
    );

    final result = await api.getDepartmentsByUnitId('unit-1');

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'dep-1');
  });

  test('updateParticipantRole sends PUT payload', () async {
    when(
      () => dio.put<Map<String, dynamic>>(
        '/v1/core/church/unit/departments/dep-1/integrants',
        data: {'membershipId': 'membership-1', 'type': 'LEADER'},
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/departments/dep-1/integrants',
        ),
        data: const {},
      ),
    );

    await api.updateParticipantRole('dep-1', {
      'membershipId': 'membership-1',
      'type': 'LEADER',
    });

    verify(
      () => dio.put<Map<String, dynamic>>(
        '/v1/core/church/unit/departments/dep-1/integrants',
        data: {'membershipId': 'membership-1', 'type': 'LEADER'},
      ),
    ).called(1);
  });

  test('removeParticipant sends DELETE payload', () async {
    when(
      () => dio.delete<void>(
        '/v1/core/church/unit/departments/dep-1/integrants',
        data: {'membershipId': 'membership-1', 'type': 'INTEGRANT'},
      ),
    ).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/departments/dep-1/integrants',
        ),
      ),
    );

    await api.removeParticipant('dep-1', {
      'membershipId': 'membership-1',
      'type': 'INTEGRANT',
    });

    verify(
      () => dio.delete<void>(
        '/v1/core/church/unit/departments/dep-1/integrants',
        data: {'membershipId': 'membership-1', 'type': 'INTEGRANT'},
      ),
    ).called(1);
  });

  test('getRoles accepts direct list response', () async {
    when(() => dio.get<dynamic>('/v1/core/roles')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/core/roles'),
        data: [
          {'id': 'role-1', 'name': 'Vocal'},
        ],
      ),
    );

    final result = await api.getRoles();

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'role-1');
  });

  test('getRoles accepts enveloped list response', () async {
    when(() => dio.get<dynamic>('/v1/core/roles')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/core/roles'),
        data: {
          'content': [
            {'id': 'role-1', 'name': 'Vocal'},
          ],
        },
      ),
    );

    final result = await api.getRoles();

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'role-1');
  });

  test('createRole sends POST payload', () async {
    when(
      () => dio.post<dynamic>('/v1/core/roles', data: {'name': 'Vocal'}),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/core/roles'),
        data: {
          'data': {'id': 'role-1', 'name': 'Vocal'},
        },
      ),
    );

    final result = await api.createRole({'name': 'Vocal'});

    expect(result['id'], 'role-1');
    verify(
      () => dio.post<dynamic>('/v1/core/roles', data: {'name': 'Vocal'}),
    ).called(1);
  });

  test('getDepartmentLineups accepts direct list response', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/unit/departments/dep-1/lineups'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/departments/dep-1/lineups',
        ),
        data: [
          {'id': 'lineup-1', 'name': 'Culto'},
        ],
      ),
    );

    final result = await api.getDepartmentLineups('dep-1');

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'lineup-1');
  });

  test('getDepartmentLineups accepts enveloped list response', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/unit/departments/dep-1/lineups'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/departments/dep-1/lineups',
        ),
        data: {
          'lineups': [
            {'id': 'lineup-1', 'name': 'Culto'},
          ],
        },
      ),
    );

    final result = await api.getDepartmentLineups('dep-1');

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'lineup-1');
  });

  test('createDepartmentLineup sends POST payload', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/core/church/unit/departments/dep-1/lineups',
        data: {'name': 'Culto'},
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/departments/dep-1/lineups',
        ),
        data: {'id': 'lineup-1', 'name': 'Culto'},
      ),
    );

    final result = await api.createDepartmentLineup('dep-1', {'name': 'Culto'});

    expect(result['id'], 'lineup-1');
    verify(
      () => dio.post<dynamic>(
        '/v1/core/church/unit/departments/dep-1/lineups',
        data: {'name': 'Culto'},
      ),
    ).called(1);
  });

  test('createDepartmentLineup unwraps department lineup response', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/core/church/unit/departments/dep-1/lineups',
        data: {'name': 'Culto'},
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/departments/dep-1/lineups',
        ),
        data: {
          'departmentLineup': {'id': 'lineup-1', 'name': 'Culto'},
        },
      ),
    );

    final result = await api.createDepartmentLineup('dep-1', {'name': 'Culto'});

    expect(result['id'], 'lineup-1');
    expect(result['name'], 'Culto');
  });

  test('getLineupById sends GET route', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/unit/lineups/lineup-1'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/lineups/lineup-1',
        ),
        data: {
          'lineup': {'id': 'lineup-1'},
        },
      ),
    );

    final result = await api.getLineupById('lineup-1');

    expect(result['id'], 'lineup-1');
  });

  test('getLineupWithItems sends GET route', () async {
    when(
      () =>
          dio.get<dynamic>('/v1/core/church/unit/lineups/lineup-1/with-items'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/lineups/lineup-1/with-items',
        ),
        data: {
          'data': {'id': 'lineup-1', 'items': <Map<String, dynamic>>[]},
        },
      ),
    );

    final result = await api.getLineupWithItems('lineup-1');

    expect(result['id'], 'lineup-1');
  });

  test('updateLineup sends PUT payload', () async {
    when(
      () => dio.put<dynamic>(
        '/v1/core/church/unit/lineups/lineup-1',
        data: {'name': 'Culto atualizado'},
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/lineups/lineup-1',
        ),
        data: {'id': 'lineup-1', 'name': 'Culto atualizado'},
      ),
    );

    await api.updateLineup('lineup-1', {'name': 'Culto atualizado'});

    verify(
      () => dio.put<dynamic>(
        '/v1/core/church/unit/lineups/lineup-1',
        data: {'name': 'Culto atualizado'},
      ),
    ).called(1);
  });

  test('deleteLineup sends DELETE route', () async {
    when(
      () => dio.delete<void>('/v1/core/church/unit/lineups/lineup-1'),
    ).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/lineups/lineup-1',
        ),
      ),
    );

    await api.deleteLineup('lineup-1');

    verify(
      () => dio.delete<void>('/v1/core/church/unit/lineups/lineup-1'),
    ).called(1);
  });

  test('getLineupItems accepts direct list response', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/unit/lineups/lineup-1/items'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/lineups/lineup-1/items',
        ),
        data: [
          {'id': 'item-1'},
        ],
      ),
    );

    final result = await api.getLineupItems('lineup-1');

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'item-1');
  });

  test('getLineupItems accepts enveloped list response', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/unit/lineups/lineup-1/items'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/lineups/lineup-1/items',
        ),
        data: {
          'items': [
            {'id': 'item-1'},
          ],
        },
      ),
    );

    final result = await api.getLineupItems('lineup-1');

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'item-1');
  });

  test(
    'createLineupItem sends lineup id in route and item data in payload',
    () async {
      when(
        () => dio.post<dynamic>(
          '/v1/core/church/unit/lineups/lineup-1/items',
          data: {'roleId': 'role-1', 'description': 'Vocal principal'},
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/v1/core/church/unit/lineups/lineup-1/items',
          ),
          data: {
            'item': {'id': 'item-1'},
          },
        ),
      );

      final result = await api.createLineupItem('lineup-1', {
        'roleId': 'role-1',
        'description': 'Vocal principal',
      });

      expect(result['id'], 'item-1');
      verify(
        () => dio.post<dynamic>(
          '/v1/core/church/unit/lineups/lineup-1/items',
          data: {'roleId': 'role-1', 'description': 'Vocal principal'},
        ),
      ).called(1);
    },
  );

  test('updateLineupItem sends PUT payload', () async {
    when(
      () => dio.put<dynamic>(
        '/v1/core/church/unit/lineups/items/item-1',
        data: {'description': 'Vocal de apoio'},
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/lineups/items/item-1',
        ),
        data: {'id': 'item-1', 'description': 'Vocal de apoio'},
      ),
    );

    await api.updateLineupItem('item-1', {'description': 'Vocal de apoio'});

    verify(
      () => dio.put<dynamic>(
        '/v1/core/church/unit/lineups/items/item-1',
        data: {'description': 'Vocal de apoio'},
      ),
    ).called(1);
  });

  test('deleteLineupItem sends DELETE route', () async {
    when(
      () => dio.delete<void>('/v1/core/church/unit/lineups/items/item-1'),
    ).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/unit/lineups/items/item-1',
        ),
      ),
    );

    await api.deleteLineupItem('item-1');

    verify(
      () => dio.delete<void>('/v1/core/church/unit/lineups/items/item-1'),
    ).called(1);
  });
}
