import 'package:client/core/domain/session_permissions.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IfPermission extends ConsumerWidget {
  const IfPermission({
    super.key,
    required this.check,
    required this.child,
    this.fallback,
    this.loading,
  });

  final bool Function(SessionPermissions permissions) check;
  final Widget child;
  final Widget? fallback;
  final Widget? loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(sessionPermissionsProvider);

    return permissionsAsync.when(
      loading: () => loading ?? const SizedBox.shrink(),
      error: (_, _) => fallback ?? const SizedBox.shrink(),
      data: (permissions) {
        if (check(permissions)) return child;
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
