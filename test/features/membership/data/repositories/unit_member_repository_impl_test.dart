import 'package:client/features/membership/data/datasources/unit_member_api.dart';
import 'package:client/features/membership/data/repositories/unit_member_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUnitMemberApi extends Mock implements UnitMemberApi {}

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockUnitMemberApi api;
  late _MockDio dio;
  late UnitMemberRepositoryImpl repository;

  setUp(() {
    api = _MockUnitMemberApi();
    dio = _MockDio();
    repository = UnitMemberRepositoryImpl(api, dio);
  });

  test('preserves camelCase profileImageId from members response', () async {
    when(
      () => dio.get<List<dynamic>>('/v1/core/church/units/unit-1/members'),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/unit-1/members',
        ),
        data: [
          {
            'id': 'membership-1',
            'unitId': 'unit-1',
            'affiliation': 'MEMBER',
            'person': {
              'id': 'person-1',
              'fullName': 'Ana Maria',
              'gender': 'FEMALE',
              'profileImageId': 'image-1',
            },
          },
        ],
      ),
    );

    final result = await repository.getUnitMembers('unit-1');

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (members) {
      expect(members.single.profileImageId, 'image-1');
    });
  });

  test('preserves snake_case profile_image_id from members response', () async {
    when(
      () => dio.get<List<dynamic>>('/v1/core/church/units/unit-1/members'),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/unit-1/members',
        ),
        data: [
          {
            'id': 'membership-1',
            'unit_id': 'unit-1',
            'affiliation': 'MEMBER',
            'person': {
              'id': 'person-1',
              'full_name': 'Ana Maria',
              'gender': 'FEMALE',
              'profile_image_id': 'image-2',
            },
          },
        ],
      ),
    );

    final result = await repository.getUnitMembers('unit-1');

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (members) {
      expect(members.single.profileImageId, 'image-2');
    });
  });
}
