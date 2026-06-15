import 'package:client/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class UserAgendaHeader extends StatelessWidget {
  const UserAgendaHeader({super.key, required this.onFilterPressed});

  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Agenda',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Material(
          color: AppColors.primaryDark.withValues(alpha: 0.10),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            tooltip: 'Filtros',
            onPressed: onFilterPressed,
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryDark),
          ),
        ),
      ],
    );
  }
}
