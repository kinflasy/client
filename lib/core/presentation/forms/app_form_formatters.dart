import 'package:flutter/services.dart';

String digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

DateTime? parseBrazilianDate(String value) {
  final digits = digitsOnly(value);
  if (digits.length != 8) return null;

  final day = int.tryParse(digits.substring(0, 2));
  final month = int.tryParse(digits.substring(2, 4));
  final year = int.tryParse(digits.substring(4, 8));
  if (day == null || month == null || year == null) return null;

  final parsed = DateTime.tryParse(
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}',
  );
  if (parsed == null) return null;
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }

  return parsed;
}

String formatBrazilianDate(DateTime? date) {
  if (date == null) return '';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String normalizePhone(String value) => digitsOnly(value);

bool isCompleteBrazilianPhone(String value) {
  final digits = normalizePhone(value);
  return digits.length == 10 || digits.length == 11;
}

String formatBrazilianPhone(String value) {
  final digits = normalizePhone(value);
  if (digits.isEmpty) return '';

  final limited = digits.substring(0, digits.length.clamp(0, 11));
  final buffer = StringBuffer();

  if (limited.isNotEmpty) {
    buffer.write('(');
    buffer.write(limited.substring(0, limited.length.clamp(0, 2)));
  }
  if (limited.length >= 2) {
    buffer.write(') ');
  }

  if (limited.length > 2) {
    final local = limited.substring(2);
    final splitIndex = local.length > 8 ? 5 : 4;
    final prefix = local.substring(0, local.length.clamp(0, splitIndex));
    buffer.write(prefix);

    if (local.length > splitIndex) {
      buffer.write('-');
      buffer.write(local.substring(splitIndex));
    }
  }

  return buffer.toString();
}

class DateTextInputFormatter extends TextInputFormatter {
  const DateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length && i < 8; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class BrazilianPhoneTextInputFormatter extends TextInputFormatter {
  const BrazilianPhoneTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatBrazilianPhone(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
