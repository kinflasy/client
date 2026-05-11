String formatEventDateRange(DateTime start, DateTime end) {
  final startLabel = _formatDateTime(start);
  final endLabel = _formatDateTime(end);
  return '$startLabel - $endLabel';
}

String _formatDateTime(DateTime value) {
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
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} $hour:$minute';
}
