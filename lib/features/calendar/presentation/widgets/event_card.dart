import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/presentation/widgets/event_date_formatters.dart';
import 'package:client/features/calendar/presentation/widgets/event_image.dart';
import 'package:client/features/church/presentation/widgets/church_unit_media.dart';
import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.organizerLabel,
    this.unitAvatarDisplayName,
    this.unitAvatarImageId,
    this.unitAvatarImageUrl,
  });

  final CalendarEventEntity event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? organizerLabel;
  final String? unitAvatarDisplayName;
  final String? unitAvatarImageId;
  final String? unitAvatarImageUrl;

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
              _EventOrganizerHeader(
                label: organizerLabel,
                dateLabel: formatEventDateRange(
                  event.startDateTime,
                  event.endDateTime,
                ),
                onEdit: onEdit,
                onDelete: onDelete,
                unitAvatarDisplayName: unitAvatarDisplayName,
                unitAvatarImageId: unitAvatarImageId,
                unitAvatarImageUrl: unitAvatarImageUrl,
              ),
              const SizedBox(height: 12),
              if (_hasImage) ...[
                EventImage(imageId: event.cardImageId!.trim()),
                const SizedBox(height: 12),
              ],
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
              const SizedBox(height: 2),
              const Text(
                '... abrir',
                style: TextStyle(color: AppColors.textSecondary),
              ),
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
  const _EventOrganizerHeader({
    required this.label,
    required this.dateLabel,
    required this.onEdit,
    required this.onDelete,
    required this.unitAvatarDisplayName,
    required this.unitAvatarImageId,
    required this.unitAvatarImageUrl,
  });

  final String? label;
  final String dateLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? unitAvatarDisplayName;
  final String? unitAvatarImageId;
  final String? unitAvatarImageUrl;

  @override
  Widget build(BuildContext context) {
    final text = label?.trim();

    return Row(
      children: [
        _EventOrganizerAvatar(
          displayName: _avatarDisplayName(text),
          unitAvatarImageId: unitAvatarImageId,
          unitAvatarImageUrl: unitAvatarImageUrl,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text == null || text.isEmpty ? 'Organizador' : text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (onEdit != null || onDelete != null) ...[
          const SizedBox(width: 8),
          PopupMenuButton<_EventCardMenuAction>(
            tooltip: 'Opções do evento',
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (action) {
              switch (action) {
                case _EventCardMenuAction.edit:
                  onEdit?.call();
                  break;
                case _EventCardMenuAction.delete:
                  onDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (onEdit != null)
                const PopupMenuItem(
                  value: _EventCardMenuAction.edit,
                  child: Text('Editar'),
                ),
              if (onDelete != null)
                PopupMenuItem(
                  value: _EventCardMenuAction.delete,
                  child: Text(
                    'Excluir',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _avatarDisplayName(String? organizerText) {
    final unitName = unitAvatarDisplayName?.trim();
    if (unitName != null && unitName.isNotEmpty) return unitName;

    if (organizerText == null || organizerText.isEmpty) return 'Organizador';
    return organizerText;
  }
}

enum _EventCardMenuAction { edit, delete }

class _EventOrganizerAvatar extends StatelessWidget {
  const _EventOrganizerAvatar({
    required this.displayName,
    required this.unitAvatarImageId,
    required this.unitAvatarImageUrl,
  });

  final String displayName;
  final String? unitAvatarImageId;
  final String? unitAvatarImageUrl;

  @override
  Widget build(BuildContext context) {
    // TODO: quando o departamento tiver avatar próprio, usar a imagem dele
    // primeiro e manter este avatar da unidade como fallback.
    return ChurchUnitAvatar(
      displayName: displayName,
      radius: 18,
      imageId: unitAvatarImageId,
      imageUrl: unitAvatarImageUrl,
    );
  }
}
