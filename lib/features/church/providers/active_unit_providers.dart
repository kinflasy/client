import 'package:client/features/church/data/datasources/active_unit_storage.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeUnitStorageProvider = Provider<ActiveUnitStorage>(
  (ref) => ActiveUnitStorage(),
);

final activeUnitProvider =
    AsyncNotifierProvider<ActiveUnitNotifier, MembershipEntity?>(
      ActiveUnitNotifier.new,
    );

class ActiveUnitNotifier extends AsyncNotifier<MembershipEntity?> {
  @override
  Future<MembershipEntity?> build() async {
    final memberships = await ref.watch(membershipProvider.future);
    final storage = ref.read(activeUnitStorageProvider);
    final selectedUnitId = await storage.readSelectedUnitId();

    return resolveActiveMembershipSelection(
      memberships: memberships,
      selectedUnitId: selectedUnitId,
      persistSelectedUnitId: storage.saveSelectedUnitId,
      clearSelectedUnitId: storage.clearSelectedUnitId,
    );
  }

  Future<void> selectUnit(String unitId) async {
    final memberships = await ref.read(membershipProvider.future);
    final selectedMembership = _findMembership(memberships, unitId);
    if (selectedMembership == null) {
      throw StateError('Unidade selecionada não pertence à sessão atual.');
    }

    await ref.read(activeUnitStorageProvider).saveSelectedUnitId(unitId);
    state = AsyncData(selectedMembership);
  }
}

Future<MembershipEntity?> resolveActiveMembershipSelection({
  required List<MembershipEntity> memberships,
  required String? selectedUnitId,
  required Future<void> Function(String unitId) persistSelectedUnitId,
  required Future<void> Function() clearSelectedUnitId,
}) async {
  if (memberships.isEmpty) {
    if (_hasText(selectedUnitId)) {
      await clearSelectedUnitId();
    }
    return null;
  }

  final selectedMembership = _findMembership(memberships, selectedUnitId);
  if (selectedMembership != null) {
    return selectedMembership;
  }

  final fallback = memberships.first;
  if (_hasText(selectedUnitId)) {
    await persistSelectedUnitId(fallback.unitId);
  }
  return fallback;
}

MembershipEntity? _findMembership(
  List<MembershipEntity> memberships,
  String? unitId,
) {
  if (!_hasText(unitId)) return null;

  for (final membership in memberships) {
    if (membership.unitId == unitId) {
      return membership;
    }
  }
  return null;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
