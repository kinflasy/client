import 'package:client/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MenuSectionLabel extends StatelessWidget {
  const MenuSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}

class MenuCardGrid extends StatelessWidget {
  const MenuCardGrid({super.key, required this.cards});

  final List<MenuGridCardData> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 126,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return MenuGridCard(
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

class MenuGridCard extends StatelessWidget {
  const MenuGridCard({
    super.key,
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
    const backgroundColor = AppColors.surfaceContainerHigh;
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
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

class MenuGridCardData {
  const MenuGridCardData({
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
