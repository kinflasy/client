import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/providers/register_member_providers.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unit_member_providers.g.dart';

const _memberFilterSentinel = Object();

class MemberFilterState extends Equatable {
  const MemberFilterState({
    this.affiliations = const {'MEMBER'},
    this.gender,
    this.minAge,
    this.maxAge,
  });

  static const defaultState = MemberFilterState();

  final Set<String> affiliations;
  final String? gender;
  final int? minAge;
  final int? maxAge;

  bool get hasActiveAgeRange => minAge != null || maxAge != null;

  MemberFilterState copyWith({
    Set<String>? affiliations,
    Object? gender = _memberFilterSentinel,
    Object? minAge = _memberFilterSentinel,
    Object? maxAge = _memberFilterSentinel,
  }) {
    return MemberFilterState(
      affiliations: affiliations ?? this.affiliations,
      gender: identical(gender, _memberFilterSentinel)
          ? this.gender
          : gender as String?,
      minAge: identical(minAge, _memberFilterSentinel)
          ? this.minAge
          : minAge as int?,
      maxAge: identical(maxAge, _memberFilterSentinel)
          ? this.maxAge
          : maxAge as int?,
    );
  }

  @override
  List<Object?> get props => [affiliations, gender, minAge, maxAge];
}

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
class MemberFilter extends _$MemberFilter {
  @override
  MemberFilterState build() => MemberFilterState.defaultState;

  void setAffiliations(Set<String> affiliations) {
    state = state.copyWith(affiliations: affiliations);
  }

  void setGender(String? gender) {
    state = state.copyWith(gender: gender);
  }

  void setAgeRange(int? minAge, int? maxAge) {
    state = state.copyWith(minAge: minAge, maxAge: maxAge);
  }

  void reset() {
    state = MemberFilterState.defaultState;
  }
}

@riverpod
AsyncValue<List<UnitMemberEntity>> filteredMembers(Ref ref, String unitId) {
  final rawAsync = ref.watch(rawUnitMembersProvider(unitId));
  final query = ref.watch(memberSearchQueryProvider);
  final filters = ref.watch(memberFilterProvider);

  return rawAsync.whenData((members) {
    var filtered = [...members];

    if (filters.affiliations.isNotEmpty) {
      filtered = filtered
          .where((member) => filters.affiliations.contains(member.affiliation))
          .toList();
    } else {
      return <UnitMemberEntity>[];
    }

    if (filters.gender != null) {
      filtered = filtered
          .where((member) => member.gender.toUpperCase() == filters.gender)
          .toList();
    }

    if (filters.hasActiveAgeRange) {
      filtered = filtered.where((member) {
        final age = calculateAge(member.birthDate);
        if (age == null) return false;
        if (filters.minAge != null && age < filters.minAge!) return false;
        if (filters.maxAge != null && age > filters.maxAge!) return false;
        return true;
      }).toList();
    }

    final normalizedQuery = normalizeSearchTerm(query);
    if (normalizedQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        final name = normalizeSearchTerm(member.fullName);
        final nickname = normalizeSearchTerm(member.nickname ?? '');
        return name.contains(normalizedQuery) ||
            nickname.contains(normalizedQuery);
      }).toList();
    }

    filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
    return filtered;
  });
}

int? calculateAge(DateTime? birthDate) {
  if (birthDate == null) return null;

  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }

  return age;
}
