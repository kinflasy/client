import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_card_summary_entity.dart';
import 'package:client/features/scale/domain/entities/scale_assignment_person_entity.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:flutter/material.dart';

class DepartmentScaleCard extends StatefulWidget {
  const DepartmentScaleCard({super.key, required this.scale, this.onTap});

  final DepartmentScaleCardSummaryEntity scale;
  final VoidCallback? onTap;

  @override
  State<DepartmentScaleCard> createState() => _DepartmentScaleCardState();
}

class _DepartmentScaleCardState extends State<DepartmentScaleCard> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.scale.base.scale.calendarEvent;
    final lineupSection = _buildLineupSection();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: AppColors.secondary),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatScaleDate(event.startDateTime).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
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
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildLineupSection() {
    if (widget.scale.base.hasLineupFailure) return null;

    final roleSummaries = widget.scale.peopleLoadFailed
        ? _roleSummariesFromLineupItems(
            widget.scale.base.lineup?.items ?? const <LineupItemEntity>[],
          )
        : widget.scale.roleSummaries;

    if (roleSummaries.isEmpty) {
      return const Text(
        'Nenhuma função definida',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    final visibleSummaries = _isExpanded
        ? roleSummaries
        : roleSummaries.take(3).toList();
    final hiddenCount = roleSummaries.length - visibleSummaries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < visibleSummaries.length; index++) ...[
          _LineupFunctionRow(summary: visibleSummaries[index]),
          if (index < visibleSummaries.length - 1) const SizedBox(height: 6),
        ],
        if (roleSummaries.length > 3) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(92, 35),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,                
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'Mostrar menos' : 'Ver tudo (+$hiddenCount)',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LineupFunctionRow extends StatelessWidget {
  const _LineupFunctionRow({required this.summary});

  final ScaleRoleAssignmentsEntity summary;

  @override
  Widget build(BuildContext context) {
    final label = _lineupItemLabel(summary.item);
    final names = summary.people
        .map((person) => person.displayName.trim())
        .where((name) => name.isNotEmpty)
        .join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            label.isEmpty ? 'Função sem nome' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        if (names.isNotEmpty) ...[
          const SizedBox(width: 5),
          Expanded(child: _ScrollableNamesFade(text: names)),
        ],
      ],
    );
  }
}

class _ScrollableNamesFade extends StatelessWidget {
  const _ScrollableNamesFade({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.86, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        key: const Key('department-scale-card-names-scroll'),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

String _lineupItemLabel(LineupItemEntity item) {
  final roleName = item.role?.name.trim() ?? '';
  if (roleName.isNotEmpty) return roleName;
  return item.description.trim();
}

List<ScaleRoleAssignmentsEntity> _roleSummariesFromLineupItems(
  List<LineupItemEntity> items,
) {
  final itemsByRoleId = <String, LineupItemEntity>{};
  final capacityByRoleId = <String, int>{};

  for (final item in items) {
    final label = _lineupItemLabel(item);
    if (label.isEmpty) continue;

    itemsByRoleId.putIfAbsent(item.roleId, () => item);
    capacityByRoleId[item.roleId] = (capacityByRoleId[item.roleId] ?? 0) + 1;
  }

  return itemsByRoleId.entries
      .map(
        (entry) => ScaleRoleAssignmentsEntity(
          item: entry.value,
          people: const <ScaleAssignmentPersonEntity>[],
          capacity: capacityByRoleId[entry.key] ?? 1,
        ),
      )
      .toList();
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

  return '$weekday, ${dateTime.day} $month · $hour:$minute';
}
