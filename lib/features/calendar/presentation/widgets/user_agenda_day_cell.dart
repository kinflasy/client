import 'package:client/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class UserAgendaDayMarkers {
  const UserAgendaDayMarkers({
    this.hasEvent = false,
    this.hasUserScale = false,
    this.hasBirthday = false,
  });

  final bool hasEvent;
  final bool hasUserScale;
  final bool hasBirthday;
}

class UserAgendaDayCell extends StatelessWidget {
  const UserAgendaDayCell({
    super.key,
    required this.date,
    required this.isInFocusedMonth,
    required this.isToday,
    required this.isSelected,
    required this.markers,
    required this.onSelected,
  });

  final DateTime date;
  final bool isInFocusedMonth;
  final bool isToday;
  final bool isSelected;
  final UserAgendaDayMarkers markers;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final textColor = isToday ? AppColors.surface : AppColors.textPrimary;

    return Expanded(
      child: Opacity(
        opacity: isInFocusedMonth ? 1 : 0.34,
        child: Semantics(
          button: true,
          selected: isSelected,
          label: 'Dia ${date.day}',
          child: Center(
            child: SizedBox(
              width: 38,
              height: 38,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(date),
                  customBorder: const CircleBorder(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _DayCircle(
                        isToday: isToday,
                        isSelected: isSelected,
                        markers: markers,
                      ),
                      Text(
                        date.day.toString(),
                        maxLines: 1,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (markers.hasBirthday) const _BirthdayDot(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.isToday,
    required this.isSelected,
    required this.markers,
  });

  final bool isToday;
  final bool isSelected;
  final UserAgendaDayMarkers markers;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = markers.hasUserScale
        ? AppColors.quaternary
        : AppColors.primary;

    Color? fillColor;
    Border? border;

    if (isToday) {
      fillColor = AppColors.primaryDark;
    } else if (markers.hasUserScale || markers.hasEvent) {
      fillColor = indicatorColor.withValues(alpha: 0.16);
    }

    if (isSelected && !isToday) {
      border = Border.all(color: AppColors.primary, width: 1.8);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: border,
      ),
    );
  }
}

class _BirthdayDot extends StatelessWidget {
  const _BirthdayDot();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      bottom: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          color: AppColors.tertiary,
        ),
        child: SizedBox(width: 6, height: 4),
      ),
    );
  }
}
