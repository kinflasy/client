import 'package:client/features/church/data/datasources/active_unit_storage.dart';
import 'package:client/features/church/providers/active_unit_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeActiveUnitStorage implements ActiveUnitStorage {
  String? selectedUnitId;
  final savedUnitIds = <String>[];
  var clearCount = 0;

  @override
  Future<String?> readSelectedUnitId() async => selectedUnitId;

  @override
  Future<void> saveSelectedUnitId(String unitId) async {
    selectedUnitId = unitId;
    savedUnitIds.add(unitId);
  }

  @override
  Future<void> clearSelectedUnitId() async {
    selectedUnitId = null;
    clearCount++;
  }
}

const _memberships = [
  MembershipEntity(id: 'membership-1', unitId: 'unit-1', affiliation: 'MEMBER'),
  MembershipEntity(
    id: 'membership-2',
    unitId: 'unit-2',
    affiliation: 'CONGREGATED',
  ),
];

void main() {
  test('valid persisted selection picks matching membership', () async {
    final saved = <String>[];

    final result = await resolveActiveMembershipSelection(
      memberships: _memberships,
      selectedUnitId: 'unit-2',
      persistSelectedUnitId: (unitId) async => saved.add(unitId),
      clearSelectedUnitId: () async => fail('should not clear'),
    );

    expect(result, _memberships.last);
    expect(saved, isEmpty);
  });

  test('invalid persisted selection falls back to first membership', () async {
    final saved = <String>[];

    final result = await resolveActiveMembershipSelection(
      memberships: _memberships,
      selectedUnitId: 'missing-unit',
      persistSelectedUnitId: (unitId) async => saved.add(unitId),
      clearSelectedUnitId: () async => fail('should not clear'),
    );

    expect(result, _memberships.first);
    expect(saved, ['unit-1']);
  });

  test('missing persisted selection falls back to first membership', () async {
    final saved = <String>[];

    final result = await resolveActiveMembershipSelection(
      memberships: _memberships,
      selectedUnitId: null,
      persistSelectedUnitId: (unitId) async => saved.add(unitId),
      clearSelectedUnitId: () async => fail('should not clear'),
    );

    expect(result, _memberships.first);
    expect(saved, isEmpty);
  });

  test('clears persisted selection when memberships are empty', () async {
    var clearCount = 0;

    final result = await resolveActiveMembershipSelection(
      memberships: const [],
      selectedUnitId: 'unit-1',
      persistSelectedUnitId: (_) async => fail('should not persist'),
      clearSelectedUnitId: () async => clearCount++,
    );

    expect(result, isNull);
    expect(clearCount, 1);
  });

  test(
    'selectUnit persists the chosen unit and updates notifier state',
    () async {
      final repository = _MockMembershipRepository();
      final storage = _FakeActiveUnitStorage();
      when(
        () => repository.getMyMemberships(),
      ).thenAnswer((_) async => const Right(_memberships));

      final container = ProviderContainer(
        overrides: [
          membershipRepositoryProvider.overrideWithValue(repository),
          activeUnitStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(activeUnitProvider.future),
        _memberships.first,
      );

      await container.read(activeUnitProvider.notifier).selectUnit('unit-2');

      expect(storage.selectedUnitId, 'unit-2');
      expect(storage.savedUnitIds, ['unit-2']);
      expect(
        container.read(activeUnitProvider).requireValue,
        _memberships.last,
      );
    },
  );
}
