import 'package:client/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MenuQuickActionsRow extends StatelessWidget {
  const MenuQuickActionsRow({super.key, required this.actions});

  final List<MenuQuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          Expanded(
            child: MenuQuickActionButton(
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

class MenuQuickActionButton extends StatelessWidget {
  const MenuQuickActionButton({
    super.key,
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
    final isEnabled = onTap != null;

    final iconSurface = Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.surfaceContainerHigh
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: isEnabled ? AppColors.textPrimary : AppColors.textPrimary,
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
              child: MenuNotificationBadge(count: badgeCount!),
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

class MenuNotificationBadge extends StatelessWidget {
  const MenuNotificationBadge({super.key, required this.count});

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

class MenuQuickActionData {
  const MenuQuickActionData({
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
