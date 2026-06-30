import 'package:client/features/membership/data/datasources/unit_member_api.dart';
import 'package:client/features/membership/data/models/activate_member_request_model.dart';
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
              'type': 'INACTIVE',
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
      expect(members.single.personType.name, 'inactive');
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
              'type': 'USER',
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

  test('identifies user by username with normalized route', () async {
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/users/identify/@ana'),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/users/identify/@ana'),
        data: {
          'id': 'user-1',
          'username': 'ana',
          'nickname': 'Aninha',
          'profileImageId': 'image-1',
        },
      ),
    );

    final result = await repository.identifyUserByUsername('@ana');

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (user) {
      expect(user.id, 'user-1');
      expect(user.username, 'ana');
      expect(user.profileImageId, 'image-1');
    });
  });

  test('activates member with backend payload', () async {
    when(
      () => api.activateMember({
        'inactivePersonId': 'person-1',
        'username': 'ana',
      }),
    ).thenAnswer((_) async {});

    final result = await repository.activateMember(
      const ActivateMemberRequestModel(
        inactivePersonId: 'person-1',
        username: 'ana',
      ),
    );

    expect(result.isRight(), isTrue);
    verify(
      () => api.activateMember({
        'inactivePersonId': 'person-1',
        'username': 'ana',
      }),
    ).called(1);
  });
}
