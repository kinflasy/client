import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateDepartmentScaleScreen extends ConsumerStatefulWidget {
  const CreateDepartmentScaleScreen({super.key, required this.departmentId});

  final String departmentId;

  @override
  ConsumerState<CreateDepartmentScaleScreen> createState() =>
      _CreateDepartmentScaleScreenState();
}

class _CreateDepartmentScaleScreenState
    extends ConsumerState<CreateDepartmentScaleScreen> {
  late final EligibleDepartmentScaleEventsRequest _eventsRequest;
  String? _eventId;
  String? _lineupId;

  @override
  void initState() {
    super.initState();
    _eventsRequest = buildEligibleDepartmentScaleEventsRequest(
      widget.departmentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(
      eligibleDepartmentScaleEventsProvider(_eventsRequest),
    );
    final lineupsAsync = ref.watch(
      departmentLineupsProvider(widget.departmentId),
    );
    final saveState = ref.watch(createEventScaleProvider);
    final isSaving = saveState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nova escala'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildBody(
          eventsAsync: eventsAsync,
          lineupsAsync: lineupsAsync,
          isSaving: isSaving,
        ),
      ),
    );
  }

  Widget _buildBody({
    required AsyncValue<List<CalendarEventEntity>> eventsAsync,
    required AsyncValue<List<LineupEntity>> lineupsAsync,
    required bool isSaving,
  }) {
    if (eventsAsync.isLoading || lineupsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final eventsError = eventsAsync.error;
    if (eventsError != null) {
      return _InlineStatus(
        icon: Icons.event_busy_outlined,
        title: 'Não foi possível carregar os eventos.',
        subtitle: _errorMessage(eventsError),
      );
    }

    final lineupsError = lineupsAsync.error;
    if (lineupsError != null) {
      return _InlineStatus(
        icon: Icons.assignment_late_outlined,
        title: 'Não foi possível carregar as formações.',
        subtitle: _errorMessage(lineupsError),
      );
    }

    final events = eventsAsync.value ?? const [];
    final lineups = lineupsAsync.value ?? const [];

    if (events.isEmpty) {
      return const _InlineStatus(
        icon: Icons.event_note_outlined,
        title: 'Nenhum evento disponível.',
        subtitle:
            'Crie um evento futuro ou verifique se os eventos existentes já possuem escala.',
      );
    }

    if (lineups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: isSaving
                  ? null
                  : () => context.pushNamed(
                      AppRoutes.departmentScaleFormationCreateName,
                      pathParameters: {'id': widget.departmentId},
                    ),
              icon: const Icon(Icons.add),
              label: const Text('Criar formação'),
            ),
            const Expanded(
              child: _InlineStatus(
                icon: Icons.assignment_outlined,
                title: 'Nenhuma formação cadastrada.',
                subtitle:
                    'Crie uma formação de escala antes de montar a escala do evento.',
              ),
            ),
          ],
        ),
      );
    }

    final selectedEventId = events.any((event) => event.id == _eventId)
        ? _eventId
        : null;
    final selectedLineupId = lineups.any((lineup) => lineup.id == _lineupId)
        ? _lineupId
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedEventId,
          decoration: const InputDecoration(
            labelText: 'Evento *',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: events
              .map(
                (event) => DropdownMenuItem(
                  value: event.id,
                  child: Text(
                    '${event.title} · ${_formatEventDate(event.startDateTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: isSaving
              ? null
              : (value) => setState(() => _eventId = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedLineupId,
          decoration: const InputDecoration(
            labelText: 'Formação *',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: lineups
              .map(
                (lineup) => DropdownMenuItem(
                  value: lineup.id,
                  child: Text(
                    lineup.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: isSaving
              ? null
              : (value) => setState(() => _lineupId = value),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isSaving ? null : () => _createScale(events),
          child: isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar escala'),
        ),
      ],
    );
  }

  Future<void> _createScale(List<CalendarEventEntity> events) async {
    final eventId = _eventId;
    final lineupId = _lineupId;
    final messenger = ScaffoldMessenger.of(context);

    if (eventId == null || lineupId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecione um evento e uma formação.')),
      );
      return;
    }

    final selectedEvent = _findEvent(events, eventId);
    if (selectedEvent == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecione um evento e uma formação.')),
      );
      return;
    }

    final shouldContinue = await _confirmIfEventHasScale(
      selectedEvent,
      messenger,
    );
    if (!shouldContinue) return;
    if (!mounted) return;

    final result = await ref
        .read(createEventScaleProvider.notifier)
        .create(
          departmentId: widget.departmentId,
          event: selectedEvent,
          request: CalendarEventScaleRequestModel(lineupId: lineupId),
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Escala criada com sucesso.')),
        );
        Navigator.of(context).maybePop();
      },
    );
  }

  CalendarEventEntity? _findEvent(
    List<CalendarEventEntity> events,
    String eventId,
  ) {
    for (final event in events) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  Future<bool> _confirmIfEventHasScale(
    CalendarEventEntity event,
    ScaffoldMessengerState messenger,
  ) async {
    final result = await ref
        .read(calendarEventRepositoryProvider)
        .getEventScales(event.id);
    final scales = result.fold((failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return null;
    }, (scales) => scales);
    if (scales == null) return false;

    if (scales.isEmpty) return true;
    if (!mounted) return false;

    return showActionConfirmationDialog(
      context,
      title: 'Criar outra escala?',
      message: 'Já existe uma escala para esse evento.',
      confirmLabel: 'Criar outra escala',
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'Tente novamente em instantes.';
}

String _formatEventDate(DateTime dateTime) {
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
