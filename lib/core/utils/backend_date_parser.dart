DateTime? parseBackendDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  if (value is List) return _parseDateList(value);
  if (value is Map) return _parseDateMap(Map<String, dynamic>.from(value));

  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _parseDateList(List<dynamic> value) {
  if (value.length < 3) return null;

  final year = _readInt(value[0]);
  final month = _readInt(value[1]);
  final day = _readInt(value[2]);
  if (year == null || month == null || day == null) return null;

  return DateTime(year, month, day);
}

DateTime? _parseDateMap(Map<String, dynamic> value) {
  final year = _readInt(value['year']);
  final month = _readInt(value['month'] ?? value['monthValue']);
  final day = _readInt(value['day'] ?? value['dayOfMonth']);
  if (year == null || month == null || day == null) return null;

  return DateTime(year, month, day);
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
