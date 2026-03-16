import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/core/domain/enums/user_profile.dart';

part 'user_profile_providers.g.dart';

@riverpod
UserProfile currentUserProfile(Ref ref) {
  final authState = ref.watch(authProvider);
  final membershipState = ref.watch(membershipProvider);

  // 1. Sem sessão ativa
  if (authState.value == null) return UserProfile.unauthenticated;

  // 2. Membership ainda carregando ou vazia
  final memberships = membershipState.value;
  if (memberships == null || memberships.isEmpty) return UserProfile.visitor;

  // 3. Traduz o affiliation da primeira membership para o enum
  final topAffiliation = memberships.first.affiliation;
  return switch (topAffiliation) {
    'MEMBER'      => UserProfile.member,
    'CONGREGATED' => UserProfile.congregated,
    _             => UserProfile.visitor,
  };
}