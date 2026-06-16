import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/menu/presentation/widgets/menu_card_grid.dart';
import 'package:client/features/menu/presentation/widgets/menu_logout_button.dart';
import 'package:client/features/menu/presentation/widgets/menu_quick_actions.dart';
import 'package:client/features/menu/presentation/widgets/menu_user_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final hasMembership = ref.watch(hasMembershipProvider);

    final quickActions = [
      const MenuQuickActionData(
        icon: Icons.notifications_none_rounded,
        label: 'Notificações',
        onTap: null,
        badgeCount: null,
      ),
      MenuQuickActionData(
        icon: Icons.edit_outlined,
        label: 'Editar informações',
        onTap: () => context.pushNamed(AppRoutes.homeMenuEditProfileName),
      ),
      const MenuQuickActionData(
        icon: Icons.church_outlined,
        label: 'Minhas igrejas',
      ),
      const MenuQuickActionData(
        icon: Icons.settings_outlined,
        label: 'Configurações',
      ),
    ];

    final accountCards = [
      MenuGridCardData(
        icon: Icons.groups_2_outlined,
        title: 'Meus departamentos',
        semanticsHint: hasMembership
            ? 'Abre os departamentos em que você participa'
            : 'Indisponível sem vínculo com igreja',
        isEnabled: hasMembership,
        onTap: hasMembership
            ? () => context.pushNamed(AppRoutes.homeMenuMyDepartmentsName)
            : null,
      ),
      MenuGridCardData(
        icon: Icons.add_business_outlined,
        title: 'Cadastrar igreja',
        onTap: () => context.pushNamed(AppRoutes.registerChurchName),
      ),
    ];

    const otherCards = [
      MenuGridCardData(
        icon: Icons.help_outline_rounded,
        title: 'Central de ajuda',
      ),
      MenuGridCardData(
        icon: Icons.description_outlined,
        title: 'Termos de uso',
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondaryExtraLight, AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              MenuUserHeader(authState: authAsync),
              const SizedBox(height: 20),
              MenuQuickActionsRow(actions: quickActions),
              const SizedBox(height: 28),
              const MenuSectionLabel(label: 'Minha conta'),
              const SizedBox(height: 12),
              MenuCardGrid(cards: accountCards),
              const SizedBox(height: 28),
              const MenuSectionLabel(label: 'Outros'),
              const SizedBox(height: 12),
              MenuCardGrid(cards: otherCards),
              const SizedBox(height: 28),
              MenuLogoutButton(onTap: () => _confirmLogout(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Sair',
      message: 'Tem certeza que deseja sair da sua conta?',
      confirmLabel: 'Sair',
      isDestructive: true,
    );

    if (confirmed) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}
