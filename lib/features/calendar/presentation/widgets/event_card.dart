import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/presentation/widgets/event_date_formatters.dart';
import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.onTap});

  final CalendarEventEntity event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final description = event.description?.trim();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _EventTypeBadge(type: event.type),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatEventDateRange(event.startDateTime, event.endDateTime),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventTypeBadge extends StatelessWidget {
  const _EventTypeBadge({required this.type});

  final CalendarEventType type;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          _label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String get _label {
    return switch (type) {
      CalendarEventType.unit => 'Unidade',
      CalendarEventType.department => 'Departamento',
    };
  }
}
