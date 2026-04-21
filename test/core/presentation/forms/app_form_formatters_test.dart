import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateTextInputFormatter', () {
    test('formats progressive date input as DD/MM/AAAA', () {
      const formatter = DateTextInputFormatter();

      final value = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '01022026'),
      );

      expect(value.text, '01/02/2026');
    });
  });

  group('BrazilianPhoneTextInputFormatter', () {
    test('formats 10-digit numbers', () {
      const formatter = BrazilianPhoneTextInputFormatter();

      final value = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '1132654321'),
      );

      expect(value.text, '(11) 3265-4321');
    });

    test('formats 11-digit numbers', () {
      const formatter = BrazilianPhoneTextInputFormatter();

      final value = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '11987654321'),
      );

      expect(value.text, '(11) 98765-4321');
    });
  });

  group('normalizePhone', () {
    test('removes non-digit characters', () {
      expect(normalizePhone('(11) 98765-4321'), '11987654321');
    });
  });

  group('parseBrazilianDate', () {
    test('parses valid masked date', () {
      expect(parseBrazilianDate('09/04/1998'), DateTime(1998, 4, 9));
    });

    test('returns null for invalid date', () {
      expect(parseBrazilianDate('32/13/2025'), isNull);
    });
  });
}
