import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_state.dart';
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
    final agendaState = ref.watch(userAgendaViewModelProvider);
    final agendaNotifier = ref.read(userAgendaViewModelProvider.notifier);

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
              UserAgendaMonthCard(
                focusedDate: agendaState.focusedMonth,
                selectedDate: agendaState.selectedDate,
                today: agendaState.today,
                markersByDate: agendaState.dayCellMarkersByDate,
                onPreviousMonth: agendaNotifier.goToPreviousMonth,
                onNextMonth: agendaNotifier.goToNextMonth,
                onToday: agendaNotifier.goToToday,
                onDaySelected: agendaNotifier.selectDate,
              ),
              const SizedBox(height: 22),
              UserAgendaWeekList(
                groups: agendaState.weeklyGroups,
                selectedDate: agendaState.selectedDate,
                today: agendaState.today,
                focusTargetDate: agendaState.focusTargetDate,
              ),
            ],
          ),
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
