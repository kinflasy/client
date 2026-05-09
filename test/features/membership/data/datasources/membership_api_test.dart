import 'package:client/features/membership/data/datasources/membership_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late MembershipApi api;

  setUp(() {
    dio = _MockDio();
    api = MembershipApi(dio);
  });

  test('getMyMemberships accepts direct list response', () async {
    when(() => dio.get<dynamic>('/v1/core/church/units')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/core/church/units'),
        data: [
          {'id': 'membership-1', 'unitId': 'unit-1', 'affiliation': 'MEMBER'},
        ],
      ),
    );

    final result = await api.getMyMemberships();

    expect(result, hasLength(1));
    expect(result.single.id, 'membership-1');
    expect(result.single.unitId, 'unit-1');
  });

  test('getMyMemberships accepts paginated content response', () async {
    when(() => dio.get<dynamic>('/v1/core/church/units')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/core/church/units'),
        data: {
          'content': [
            {'id': 'membership-1', 'unitId': 'unit-1', 'affiliation': 'MEMBER'},
          ],
        },
      ),
    );

    final result = await api.getMyMemberships();

    expect(result, hasLength(1));
    expect(result.single.unitId, 'unit-1');
  });

  test('getMyMemberships extracts first map when item is wrapped in a list', () async {
    when(() => dio.get<dynamic>('/v1/core/church/units')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/core/church/units'),
        data: [
          [
            {'id': 'membership-1', 'unitId': 'unit-1', 'affiliation': 'MEMBER'},
          ],
        ],
      ),
    );

    final result = await api.getMyMemberships();

    expect(result, hasLength(1));
    expect(result.single.id, 'membership-1');
  });

  test('getMyMemberships reads unitId from nested unit object', () async {
    when(() => dio.get<dynamic>('/v1/core/church/units')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/core/church/units'),
        data: [
          {
            'id': 'membership-1',
            'unit': {'id': 'unit-1'},
            'affiliation': 'MEMBER',
          },
        ],
      ),
    );

    final result = await api.getMyMemberships();

    expect(result, hasLength(1));
    expect(result.single.unitId, 'unit-1');
  });
}
