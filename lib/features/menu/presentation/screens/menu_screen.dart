import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final hasMembership = ref.watch(hasMembershipProvider);

    final quickActions = const [
      _QuickActionData(
        icon: Icons.notifications_none_rounded,
        label: 'Notificações',
        onTap: null,
        badgeCount: null,
      ),
      _QuickActionData(icon: Icons.edit_outlined, label: 'Editar informações'),
      _QuickActionData(icon: Icons.church_outlined, label: 'Minhas igrejas'),
      _QuickActionData(icon: Icons.settings_outlined, label: 'Configurações'),
    ];

    final accountCards = [
      _MenuGridCardData(
        icon: Icons.groups_2_outlined,
        title: 'Meus departamentos',
        semanticsHint: hasMembership
            ? 'Área preparada para futura navegação'
            : 'Indisponível sem vínculo com igreja',
        isEnabled: hasMembership,
      ),
      _MenuGridCardData(
        icon: Icons.add_business_outlined,
        title: 'Cadastrar igreja',
        onTap: () => context.pushNamed(AppRoutes.registerChurchName),
      ),
    ];

    const otherCards = [
      _MenuGridCardData(
        icon: Icons.help_outline_rounded,
        title: 'Central de ajuda',
      ),
      _MenuGridCardData(
        icon: Icons.description_outlined,
        title: 'Termos de uso',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            _UserHeader(authState: authAsync),
            const SizedBox(height: 20),
            _QuickActionsRow(actions: quickActions),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Minha conta'),
            const SizedBox(height: 12),
            _MenuCardGrid(cards: accountCards),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Outros'),
            const SizedBox(height: 12),
            const _MenuCardGrid(cards: otherCards),
            const SizedBox(height: 28),
            _LogoutButton(onTap: () => _confirmLogout(context, ref)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sair', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.authState});

  final AsyncValue<UserEntity?> authState;

  @override
  Widget build(BuildContext context) {
    return switch (authState) {
      AsyncLoading<UserEntity?>() => const _UserHeaderLoading(),
      AsyncError<UserEntity?>() => const _UserHeaderContent(user: null),
      AsyncData<UserEntity?>(:final value) => _UserHeaderContent(user: value),
    };
  }
}

class _UserHeaderContent extends StatelessWidget {
  const _UserHeaderContent({required this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final displayName = _displayName(user);
    final initials = _userInitials(user);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initials,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserHeaderLoading extends StatelessWidget {
  const _UserHeaderLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 144,
            height: 20,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          Expanded(
            child: _QuickActionButton(
              icon: actions[index].icon,
              label: actions[index].label,
              onTap: actions[index].onTap,
              badgeCount: actions[index].badgeCount,
            ),
          ),
          if (index < actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;

    final iconSurface = Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isEnabled
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: isEnabled
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          iconSurface,
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              top: -4,
              right: -4,
              child: _NotificationBadge(count: badgeCount!),
            ),
        ],
      ),
    );

    return Semantics(
      label: label,
      button: onTap != null,
      enabled: isEnabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Opacity(opacity: isEnabled ? 1 : 0.84, child: content),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onError,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _MenuCardGrid extends StatelessWidget {
  const _MenuCardGrid({required this.cards});

  final List<_MenuGridCardData> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 136,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _MenuGridCard(
          icon: card.icon,
          title: card.title,
          onTap: card.onTap,
          isEnabled: card.isEnabled,
          semanticsHint: card.semanticsHint,
        );
      },
    );
  }
}

class _MenuGridCard extends StatelessWidget {
  const _MenuGridCard({
    required this.icon,
    required this.title,
    required this.isEnabled,
    this.onTap,
    this.semanticsHint,
  });

  final IconData icon;
  final String title;
  final bool isEnabled;
  final VoidCallback? onTap;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isInteractive = isEnabled && onTap != null;
    final backgroundColor = colorScheme.surfaceContainerHigh;
    final iconColor = isEnabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;
    final textColor = isEnabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: onTap != null,
      enabled: isEnabled,
      hint: semanticsHint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Opacity(
              opacity: isEnabled ? 1 : 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 30, color: iconColor),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sair',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.error,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int? badgeCount;
}

class _MenuGridCardData {
  const _MenuGridCardData({
    required this.icon,
    required this.title,
    this.onTap,
    this.isEnabled = true,
    this.semanticsHint,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isEnabled;
  final String? semanticsHint;
}

String _displayName(UserEntity? user) {
  return user?.nickname?.trim().isNotEmpty == true
      ? user!.nickname!.trim()
      : user?.fullName?.trim().isNotEmpty == true
      ? user!.fullName!.trim()
      : user?.username.trim().isNotEmpty == true
      ? user!.username.trim()
      : 'Usuário';
}

String _userInitials(UserEntity? user) {
  final rawName = _displayName(user);
  final parts = rawName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  return parts.isEmpty
      ? 'U'
      : parts.map((part) => part[0].toUpperCase()).join();
}
