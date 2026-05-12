import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/presentation/widgets/event_date_formatters.dart';
import 'package:client/features/calendar/presentation/widgets/event_image.dart';
import 'package:client/features/calendar/providers/calendar_event_actions_provider.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> showEventDetailBottomSheet(
  BuildContext context, {
  required String eventId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EventDetailBottomSheet(eventId: eventId),
  );
}

Future<void> confirmAndDeleteCalendarEvent(
  BuildContext context,
  WidgetRef ref,
  CalendarEventEntity event, {
  VoidCallback? onDeleted,
}) async {
  final confirmed = await showActionConfirmationDialog(
    context,
    title: 'Excluir evento',
    message: 'Tem certeza que deseja excluir este evento?',
    confirmLabel: 'Excluir',
    isDestructive: true,
  );

  if (!confirmed) return;

  final result = await ref
      .read(calendarEventActionsProvider.notifier)
      .deleteEvent(event.id);
  if (!context.mounted) return;

  result.fold(
    (failure) => _showEventSnackBar(context, _failureMessage(failure)),
    (_) {
      _showEventSnackBar(context, 'Evento excluído.');
      onDeleted?.call();
    },
  );
}

class _EventDetailBottomSheet extends ConsumerWidget {
  const _EventDetailBottomSheet({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(calendarEventDetailProvider(eventId));
    final canEdit =
        ref
            .watch(sessionPermissionsProvider)
            .whenOrNull(data: (permissions) => permissions.isUnitAdmin) ??
        false;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ColoredBox(
            color: AppColors.surface,
            child: SafeArea(
              top: false,
              child: eventAsync.when(
                loading: () =>
                    _EventDetailLoading(scrollController: scrollController),
                error: (error, stackTrace) =>
                    _EventDetailError(scrollController: scrollController),
                data: (event) => _EventDetailContent(
                  event: event,
                  scrollController: scrollController,
                  canEdit: canEdit,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EventDetailContent extends ConsumerWidget {
  const _EventDetailContent({
    required this.event,
    required this.scrollController,
    required this.canEdit,
  });

  final CalendarEventEntity event;
  final ScrollController scrollController;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = event.description?.trim();
    final imageId = event.cardImageId?.trim();
    final hasImage = imageId != null && imageId.isNotEmpty;
    final actionState = ref.watch(calendarEventActionsProvider);
    final isSubmitting = actionState.isLoading;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _SheetHandle(),
        const SizedBox(height: 16),
        if (hasImage) ...[
          EventImage(imageId: imageId),
          const SizedBox(height: 20),
        ],
        Text(
          event.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _DetailRow(
          icon: Icons.schedule_outlined,
          label: formatEventDateRange(event.startDateTime, event.endDateTime),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Descrição',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.45),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 24),
          _AdminActions(event: event, isSubmitting: isSubmitting),
        ],
      ],
    );
  }
}

class _AdminActions extends ConsumerWidget {
  const _AdminActions({required this.event, required this.isSubmitting});

  final CalendarEventEntity event;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () {
                      context.pop();
                      context.pushNamed(
                        AppRoutes.adminCalendarEditName,
                        pathParameters: {'id': event.id},
                      );
                    },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
            OutlinedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () => _confirmAndDeleteEvent(context, ref),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        if (isSubmitting) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _confirmAndDeleteEvent(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Excluir evento',
      message: 'Tem certeza que deseja excluir este evento?',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );

    if (!confirmed) return;

    final result = await ref
        .read(calendarEventActionsProvider.notifier)
        .deleteEvent(event.id);
    if (!context.mounted) return;

    result.fold((failure) => _showSnackBar(context, _failureMessage(failure)), (
      _,
    ) {
      _showSnackBar(context, 'Evento excluído.');
      Navigator.of(context).pop();
    });
  }

  String _failureMessage(Object failure) {
    if (failure is Failure) return failure.message;
    return failure.toString();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _failureMessage(Object failure) {
  if (failure is Failure) return failure.message;
  return failure.toString();
}

void _showEventSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _EventDetailLoading extends StatelessWidget {
  const _EventDetailLoading({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: const [
        _SheetHandle(),
        SizedBox(height: 160),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Carregando detalhes do evento...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _EventDetailError extends StatelessWidget {
  const _EventDetailError({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: const [
        _SheetHandle(),
        SizedBox(height: 140),
        Icon(
          Icons.event_busy_outlined,
          size: 40,
          color: AppColors.textSecondary,
        ),
        SizedBox(height: 12),
        Text(
          'Não foi possível carregar os detalhes do evento.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Tente novamente em instantes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
