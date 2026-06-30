import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/presentation/widgets/if_permission.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/providers/active_unit_providers.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/presentation/widgets/church_unit_media.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChurchSidebar extends ConsumerWidget {
  const ChurchSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentChurchProfileProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, stackTrace) => const SizedBox.shrink(),
          data: (profile) => _SidebarContent(
            unit: profile.unit,
            church: profile.church,
            activeMembership: profile.membership,
          ),
        ),
      ),
    );
  }
}

class _SidebarContent extends ConsumerWidget {
  const _SidebarContent({
    required this.unit,
    required this.church,
    required this.activeMembership,
  });

  final ChurchUnitEntity unit;
  final ChurchEntity church;
  final MembershipEntity activeMembership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = unit.logoUrl ?? church.logoUrl;
    final profileImageId = unit.profileImageId;
    final displayName = unit.name?.trim().isNotEmpty == true
        ? unit.name!
        : church.name;
    final memberships =
        ref.watch(membershipProvider).whenOrNull(data: (items) => items) ??
        const <MembershipEntity>[];
    final canSwitchUnit = memberships.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SidebarHeader(
          logoUrl: logoUrl,
          profileImageId: profileImageId,
          displayName: displayName,
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        IfPermission(
          check: (SessionPermissions permissions) => permissions.isUnitAdmin,
          child: const _SidebarAdminButton(),
        ),
        const Spacer(),
        if (canSwitchUnit)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Trocar unidade'),
              onPressed: () => _showUnitSelectionSheet(
                context: context,
                ref: ref,
                memberships: memberships,
                fallbackUnitName: displayName,
                activeUnitId: activeMembership.unitId,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.surfaceContainerHigh),
                minimumSize: const Size.fromHeight(44),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showUnitSelectionSheet({
    required BuildContext context,
    required WidgetRef ref,
    required List<MembershipEntity> memberships,
    required String fallbackUnitName,
    required String activeUnitId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _UnitSelectionBottomSheet(
        memberships: memberships,
        fallbackUnitName: fallbackUnitName,
        activeUnitId: activeUnitId,
        onSelected: (unitId) async {
          final router = GoRouter.of(context);
          Navigator.of(sheetContext).pop();
          Navigator.of(context).pop();
          await ref.read(activeUnitProvider.notifier).selectUnit(unitId);
          ref.invalidate(currentChurchProfileProvider);
          ref.invalidate(sessionPermissionsProvider);
          router.go(AppRoutes.homeChurch);
        },
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.logoUrl,
    required this.profileImageId,
    required this.displayName,
  });

  final String? logoUrl;
  final String? profileImageId;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ChurchUnitAvatar(
            displayName: displayName,
            radius: 24,
            imageId: profileImageId,
            imageUrl: logoUrl,
            textStyle: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarAdminButton extends StatelessWidget {
  const _SidebarAdminButton();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.admin_panel_settings_outlined,
        color: AppColors.primary,
      ),
      title: const Text(
        'Gestão da Igreja',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.pushNamed(AppRoutes.adminPanelName);
      },
    );
  }
}

class _UnitSelectionBottomSheet extends StatelessWidget {
  const _UnitSelectionBottomSheet({
    required this.memberships,
    required this.fallbackUnitName,
    required this.activeUnitId,
    required this.onSelected,
  });

  final List<MembershipEntity> memberships;
  final String fallbackUnitName;
  final String activeUnitId;
  final Future<void> Function(String unitId) onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha uma unidade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: memberships.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final membership = memberships[index];
                  final unitName = _unitDisplayName(membership);
                  final displayName = unitName.isNotEmpty
                      ? unitName
                      : membership.unitId == activeUnitId
                      ? fallbackUnitName
                      : 'Unidade';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ChurchUnitAvatar(
                      displayName: displayName,
                      radius: 20,
                      imageId: membership.unitProfileImageId,
                      imageUrl: membership.unitLogoUrl,
                    ),
                    title: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onTap: () => onSelected(membership.unitId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _unitDisplayName(MembershipEntity membership) {
    return membership.unitName?.trim() ?? '';
  }
}
