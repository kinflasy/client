import 'dart:ui';

import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_day_cell.dart';
import 'package:flutter/material.dart';

class UserAgendaMonthCard extends StatelessWidget {
  const UserAgendaMonthCard({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    required this.today,
    required this.markersByDate,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  final DateTime focusedDate;
  final DateTime selectedDate;
  final DateTime today;
  final Map<DateTime, UserAgendaDayMarkers> markersByDate;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final visibleDates = _visibleDatesForMonth(focusedDate);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.surface.withValues(alpha: 0.09),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _WeekdayLabel('Dom'),
                    _WeekdayLabel('Seg'),
                    _WeekdayLabel('Ter'),
                    _WeekdayLabel('Qua'),
                    _WeekdayLabel('Qui'),
                    _WeekdayLabel('Sex'),
                    _WeekdayLabel('Sáb'),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.6,
                  color: AppColors.surface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 14),
                _MonthHeader(
                  focusedDate: focusedDate,
                  onPreviousMonth: onPreviousMonth,
                  onNextMonth: onNextMonth,
                  onToday: onToday,
                ),
                const SizedBox(height: 18),
                for (var row = 0; row < 6; row++) ...[
                  Row(
                    children: [
                      for (var column = 0; column < 7; column++)
                        UserAgendaDayCell(
                          key: ValueKey(
                            'user-agenda-day-${_dateKey(visibleDates[(row * 7) + column])}',
                          ),
                          date: visibleDates[(row * 7) + column],
                          isInFocusedMonth:
                              visibleDates[(row * 7) + column].month ==
                              focusedDate.month,
                          isToday: DateUtils.isSameDay(
                            visibleDates[(row * 7) + column],
                            today,
                          ),
                          isSelected: DateUtils.isSameDay(
                            visibleDates[(row * 7) + column],
                            selectedDate,
                          ),
                          markers:
                              markersByDate[DateUtils.dateOnly(
                                visibleDates[(row * 7) + column],
                              )] ??
                              const UserAgendaDayMarkers(),
                          onSelected: onDaySelected,
                        ),
                    ],
                  ),
                  if (row < 5) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.focusedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  final DateTime focusedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MonthArrowButton(
                key: const ValueKey('user-agenda-previous-month'),
                icon: Icons.arrow_left_rounded,
                tooltip: 'Mês anterior',
                onPressed: onPreviousMonth,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  _formatMonthYear(focusedDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.88),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              _MonthArrowButton(
                key: const ValueKey('user-agenda-next-month'),
                icon: Icons.arrow_right_rounded,
                tooltip: 'Próximo mês',
                onPressed: onNextMonth,
              ),
            ],
          ),
        ),
        TextButton(
          key: const ValueKey('user-agenda-today-button'),
          onPressed: onToday,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Hoje'),
        ),
      ],
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: AppColors.textPrimary,
      iconSize: 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 26, height: 32),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.78),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

List<DateTime> _visibleDatesForMonth(DateTime focusedDate) {
  final firstOfMonth = DateTime(focusedDate.year, focusedDate.month);
  final daysBeforeMonth = firstOfMonth.weekday % DateTime.daysPerWeek;
  final firstVisibleDate = firstOfMonth.subtract(
    Duration(days: daysBeforeMonth),
  );

  return List.generate(
    DateTime.daysPerWeek * 6,
    (index) => DateUtils.dateOnly(firstVisibleDate.add(Duration(days: index))),
  );
}

String _formatMonthYear(DateTime date) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  return '${months[date.month - 1].toLowerCase()} ${date.year}';
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
