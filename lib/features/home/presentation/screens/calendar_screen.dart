import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_state.dart';
import 'package:client/features/calendar/presentation/widgets/event_detail_bottom_sheet.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_day_cell.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_header.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_month_card.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_week_list.dart';
import 'package:client/features/calendar/providers/user_agenda_view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(userAgendaViewModelProvider);
    final agendaNotifier = ref.read(userAgendaViewModelProvider.notifier);
    final agendaState = agendaAsync.value;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondaryExtraLight, AppColors.surface],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserAgendaHeader(onFilterPressed: () {}),
              const SizedBox(height: 22),
              if (agendaState == null)
                _InitialAgendaState(
                  isLoading: agendaAsync.isLoading,
                  errorMessage: agendaAsync.errorMessage,
                  onRetry: agendaNotifier.retry,
                )
              else ...[
                UserAgendaMonthCard(
                  focusedDate: agendaState.focusedMonth,
                  selectedDate: agendaState.selectedDate,
                  today: agendaState.today,
                  markersByDate: agendaState.dayCellMarkersByDate,
                  onPreviousMonth: () => agendaNotifier.goToPreviousMonth(),
                  onNextMonth: () => agendaNotifier.goToNextMonth(),
                  onToday: () => agendaNotifier.goToToday(),
                  onDaySelected: (date) => agendaNotifier.selectDate(date),
                ),
                const SizedBox(height: 22),
                if (agendaState.isLoading) ...[
                  const _AgendaLoadingMessage(),
                  const SizedBox(height: 14),
                ],
                if (agendaState.errorMessage != null) ...[
                  _AgendaErrorMessage(
                    message: agendaState.errorMessage!,
                    onRetry: agendaNotifier.retry,
                  ),
                  const SizedBox(height: 14),
                ],
                UserAgendaWeekList(
                  groups: agendaState.weeklyGroups,
                  selectedDate: agendaState.selectedDate,
                  today: agendaState.today,
                  focusTargetDate: agendaState.focusTargetDate,
                  onEventTap: (eventId) =>
                      showEventDetailBottomSheet(context, eventId: eventId),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialAgendaState extends StatelessWidget {
  const _InitialAgendaState({
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading || errorMessage == null) return const _AgendaLoadingMessage();

    return _AgendaErrorMessage(message: errorMessage!, onRetry: onRetry);
  }
}

class _AgendaLoadingMessage extends StatelessWidget {
  const _AgendaLoadingMessage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Carregando agenda...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaErrorMessage extends StatelessWidget {
  const _AgendaErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on UserAgendaState {
  Map<DateTime, UserAgendaDayMarkers> get dayCellMarkersByDate {
    return markersByDate.map((date, markers) {
      return MapEntry(
        date,
        UserAgendaDayMarkers(
          hasEvent: markers.hasEvent,
          hasUserScale: markers.hasUserScale,
          hasBirthday: markers.hasBirthday,
        ),
      );
    });
  }
}

extension on AsyncValue<UserAgendaState> {
  String? get errorMessage {
    final error = this.error;
    if (error == null) return null;
    if (error is Failure) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? 'Erro ao carregar agenda.' : text;
  }
}
