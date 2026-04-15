import 'package:flutter/material.dart';

class MenuLogoutButton extends StatelessWidget {
  const MenuLogoutButton({super.key, required this.onTap});

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
