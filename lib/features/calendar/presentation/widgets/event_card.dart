import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/presentation/widgets/event_date_formatters.dart';
import 'package:client/features/calendar/presentation/widgets/event_image.dart';
import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.organizerLabel,
  });

  final CalendarEventEntity event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final String? organizerLabel;

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
              _EventOrganizerHeader(label: organizerLabel, onEdit: onEdit),
              const SizedBox(height: 12),
              if (_hasImage) ...[
                EventImage(imageId: event.cardImageId!.trim()),
                const SizedBox(height: 12),
              ],
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

  bool get _hasImage {
    final imageId = event.cardImageId?.trim();
    return imageId != null && imageId.isNotEmpty;
  }
}

class _EventOrganizerHeader extends StatelessWidget {
  const _EventOrganizerHeader({required this.label, required this.onEdit});

  final String? label;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final text = label?.trim();

    return Row(
      children: [
        Expanded(
          child: Text(
            text == null || text.isEmpty ? 'Organizador' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          PopupMenuButton<_EventCardMenuAction>(
            tooltip: 'Opções do evento',
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (action) {
              switch (action) {
                case _EventCardMenuAction.edit:
                  onEdit?.call();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _EventCardMenuAction.edit,
                child: Text('Editar evento'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

enum _EventCardMenuAction { edit }

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
