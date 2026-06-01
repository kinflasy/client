import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:flutter/material.dart';

class DepartmentScaleCard extends StatefulWidget {
  const DepartmentScaleCard({super.key, required this.scale, this.onTap});

  final DepartmentScaleWithLineupEntity scale;
  final VoidCallback? onTap;

  @override
  State<DepartmentScaleCard> createState() => _DepartmentScaleCardState();
}

class _DepartmentScaleCardState extends State<DepartmentScaleCard> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.scale.scale.calendarEvent;
    final lineupSection = _buildLineupSection();

    return Material(
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatScaleDate(event.startDateTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (lineupSection != null) ...[
                      const SizedBox(height: 12),
                      lineupSection,
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

  Widget? _buildLineupSection() {
    if (widget.scale.hasLineupFailure) return null;

    final labels = (widget.scale.lineup?.items ?? const <LineupItemEntity>[])
        .map(_lineupItemLabel)
        .where((label) => label.isNotEmpty)
        .toList();

    if (labels.isEmpty) {
      return const Text(
        'Nenhuma função definida',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    final visibleLabels = _isExpanded ? labels : labels.take(3).toList();
    final hiddenCount = labels.length - visibleLabels.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < visibleLabels.length; index++) ...[
          _LineupFunctionRow(label: visibleLabels[index]),
          if (index < visibleLabels.length - 1) const SizedBox(height: 6),
        ],
        if (labels.length > 3) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                minimumSize: const Size(96, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'Mostrar menos' : 'Ver todas (+$hiddenCount)',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LineupFunctionRow extends StatelessWidget {
  const _LineupFunctionRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

String _lineupItemLabel(LineupItemEntity item) {
  final roleName = item.role?.name.trim() ?? '';
  if (roleName.isNotEmpty) return roleName;
  return item.description.trim();
}

String _formatScaleDate(DateTime dateTime) {
  const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  final weekday = weekdays[dateTime.weekday - 1];
  final month = months[dateTime.month - 1];
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$weekday, ${dateTime.day} $month - $hour:$minute';
}
