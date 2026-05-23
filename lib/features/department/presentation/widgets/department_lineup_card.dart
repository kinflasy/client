import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:flutter/material.dart';

class DepartmentLineupCard extends StatelessWidget {
  const DepartmentLineupCard({super.key, required this.lineup, this.onTap});

  final LineupEntity lineup;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final items = lineup.items ?? const [];
    final roleNames = items
        .map((item) => item.role?.name.trim() ?? item.description.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final visibleRoleNames = roleNames.take(3).toList();
    final extraCount = roleNames.length - visibleRoleNames.length;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E3E7)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lineup.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _roleCountLabel(items.length),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (visibleRoleNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final roleName in visibleRoleNames)
                      _RoleSummaryChip(label: roleName),
                    if (extraCount > 0) _RoleSummaryChip(label: '+$extraCount'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSummaryChip extends StatelessWidget {
  const _RoleSummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

String _roleCountLabel(int count) {
  if (count == 1) return '1 papel';
  return '$count papéis';
}
