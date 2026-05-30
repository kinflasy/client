import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:flutter/material.dart';

class DepartmentLineupCard extends StatelessWidget {
  const DepartmentLineupCard({super.key, required this.lineup, this.onTap});

  final LineupEntity lineup;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lineup.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((lineup.items ?? const []).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _buildRoleSummary(lineup),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

String _buildRoleSummary(LineupEntity lineup) {
  final items = lineup.items ?? const [];
  final count = items.length;
  final countLabel = count == 1 ? '1 papel' : '$count papéis';
  final roles = items
      .map((item) => item.role?.name.trim() ?? item.description.trim())
      .where((name) => name.isNotEmpty)
      .toList();

  if (roles.isEmpty) return countLabel;

  final visibleRoles = roles.take(3).toList();
  final remaining = roles.length - visibleRoles.length;
  final roleLabel = remaining > 0
      ? '${visibleRoles.join(', ')} +$remaining'
      : visibleRoles.join(', ');

  return '$countLabel · $roleLabel';
}
