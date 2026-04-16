import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/presentation/widgets/if_permission.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_providers.dart';
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
          data: (profile) =>
              _SidebarContent(unit: profile.unit, church: profile.church),
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({required this.unit, required this.church});

  final ChurchUnitEntity unit;
  final ChurchEntity church;

  @override
  Widget build(BuildContext context) {
    final logoUrl = unit.logoUrl ?? church.logoUrl;
    final displayName = unit.name?.trim().isNotEmpty == true
        ? unit.name!
        : church.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SidebarHeader(logoUrl: logoUrl, displayName: displayName),
        const Divider(height: 1),
        const SizedBox(height: 8),
        IfPermission(
          check: (SessionPermissions permissions) => permissions.isUnitAdmin,
          child: const _SidebarAdminButton(),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Trocar de igreja em breve.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.logoUrl, required this.displayName});

  final String? logoUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8F0FE),
            backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
            child: logoUrl == null
                ? Text(
                    churchInitials(displayName),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
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
