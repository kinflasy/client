import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/providers/register_member_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unit_member_providers.g.dart';

@riverpod
class MemberSearchQuery extends _$MemberSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}

@riverpod
Future<List<UnitMemberEntity>> rawUnitMembers(Ref ref, String unitId) async {
  final repo = ref.watch(unitMemberRepositoryProvider);
  final result = await repo.getUnitMembers(unitId);
  return result.fold((failure) => throw failure, (members) => members);
}

@riverpod
AsyncValue<List<UnitMemberEntity>> filteredMembers(Ref ref, String unitId) {
  final rawAsync = ref.watch(rawUnitMembersProvider(unitId));
  final query = ref.watch(memberSearchQueryProvider);

  return rawAsync.whenData((members) {
    final normalizedQuery = normalizeSearchTerm(query);
    final filtered = normalizedQuery.isEmpty
        ? [...members]
        : members.where((member) {
            final name = normalizeSearchTerm(member.fullName);
            final nickname = normalizeSearchTerm(member.nickname ?? '');
            return name.contains(normalizedQuery) ||
                nickname.contains(normalizedQuery);
          }).toList();

    filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
    return filtered;
  });
}
