String formatMonthDay(DateTime date) {
  return '--${_twoDigits(date.month)}-${_twoDigits(date.day)}';
}

({int month, int day}) parseMonthDay(String value) {
  final match = RegExp(r'^--(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) {
    throw FormatException('MonthDay invalido: $value');
  }

  final month = int.parse(match.group(1)!);
  final day = int.parse(match.group(2)!);
  if (!_isValidMonthDay(month, day)) {
    throw FormatException('MonthDay invalido: $value');
  }

  return (month: month, day: day);
}

DateTime? materializeMonthDayInRange({
  required int month,
  required int day,
  required DateTime start,
  required DateTime end,
}) {
  final normalizedStart = DateTime(start.year, start.month, start.day);
  final normalizedEnd = DateTime(end.year, end.month, end.day);

  for (var year = normalizedStart.year; year <= normalizedEnd.year; year++) {
    if (!_isValidMonthDay(month, day, year: year)) continue;
    final candidate = DateTime(year, month, day);
    if (!candidate.isBefore(normalizedStart) &&
        !candidate.isAfter(normalizedEnd)) {
      return candidate;
    }
  }

  return null;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

bool _isValidMonthDay(int month, int day, {int year = 2000}) {
  if (month < 1 || month > 12 || day < 1) return false;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  return day <= lastDayOfMonth;
}
