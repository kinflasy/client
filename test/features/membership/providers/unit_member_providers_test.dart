import 'dart:async';

import 'package:client/features/membership/data/models/unit_member_model.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:client/features/membership/domain/repositories/unit_member_repository.dart';
import 'package:client/features/membership/providers/register_member_providers.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockUnitMemberRepository extends Mock implements UnitMemberRepository {}

Future<List<UnitMemberEntity>> _readFilteredMembers(
  ProviderContainer container,
  String unitId,
) async {
  final completer = Completer<List<UnitMemberEntity>>();
  final subscription = container.listen<AsyncValue<List<UnitMemberEntity>>>(
    filteredMembersProvider(unitId),
    (previous, next) {
      if (next.hasValue && !completer.isCompleted) {
        completer.complete(next.requireValue);
      } else if (next.hasError && !completer.isCompleted) {
        completer.completeError(next.error!, next.stackTrace);
      }
    },
    fireImmediately: true,
  );

  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}

void main() {
  late _MockUnitMemberRepository repository;
  late ProviderContainer container;

  final members = [
    UnitMemberEntity(
      membershipId: '1',
      personId: 'p1',
      personType: PersonType.user,
      fullName: 'Ana Maria',
      nickname: 'Aninha',
      affiliation: 'MEMBER',
      gender: 'FEMALE',
      birthDate: DateTime(1996, 4, 10),
    ),
    UnitMemberEntity(
      membershipId: '2',
      personId: 'p2',
      personType: PersonType.user,
      fullName: 'Bruno Lima',
      affiliation: 'VISITOR',
      gender: 'MALE',
      birthDate: DateTime(2008, 4, 10),
    ),
    const UnitMemberEntity(
      membershipId: '3',
      personId: 'p3',
      personType: PersonType.user,
      fullName: 'Carla Souza',
      affiliation: 'CONGREGATED',
      gender: 'FEMALE',
    ),
  ];

  setUp(() {
    repository = _MockUnitMemberRepository();
    when(
      () => repository.getUnitMembers('unit-1'),
    ).thenAnswer((_) async => Right(members));

    container = ProviderContainer(
      overrides: [unitMemberRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'memberFilterProvider starts with default state and reset restores it',
    () {
      expect(
        container.read(memberFilterProvider),
        MemberFilterState.defaultState,
      );

      container.read(memberFilterProvider.notifier).setGender('FEMALE');
      expect(container.read(memberFilterProvider).gender, 'FEMALE');

      container.read(memberFilterProvider.notifier).reset();
      expect(
        container.read(memberFilterProvider),
        MemberFilterState.defaultState,
      );
    },
  );

  test('UnitMemberModel maps profileImageId to entity', () {
    final model = UnitMemberModel.fromJson({
      'id': 'membership-1',
      'unitId': 'unit-1',
      'affiliation': 'MEMBER',
      'person': {
        'id': 'person-1',
        'type': 'USER',
        'fullName': 'Ana Maria',
        'gender': 'FEMALE',
        'profileImageId': 'image-1',
      },
    });

    expect(model.person.profileImageId, 'image-1');
    expect(model.toEntity().profileImageId, 'image-1');
  });

  test(
    'filteredMembers applies affiliations, gender, age range and search',
    () async {
      container.read(memberFilterProvider.notifier).setAffiliations({
        'MEMBER',
        'VISITOR',
      });
      container.read(memberFilterProvider.notifier).setGender('FEMALE');
      container.read(memberFilterProvider.notifier).setAgeRange(25, 35);
      container.read(memberSearchQueryProvider.notifier).update('ana');

      final result = await _readFilteredMembers(container, 'unit-1');

      expect(result.map((member) => member.fullName).toList(), ['Ana Maria']);
    },
  );

  test(
    'filteredMembers returns empty list when no affiliation is selected',
    () async {
      container.read(memberFilterProvider.notifier).setAffiliations({});

      final result = await _readFilteredMembers(container, 'unit-1');

      expect(result, isEmpty);
    },
  );
}
