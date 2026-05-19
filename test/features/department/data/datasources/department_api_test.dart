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
}
