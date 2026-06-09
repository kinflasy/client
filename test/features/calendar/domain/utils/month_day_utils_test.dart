import 'package:client/features/calendar/domain/utils/month_day_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthDay utils', () {
    test('formata DateTime como MonthDay', () {
      expect(formatMonthDay(DateTime(2026, 6, 7)), '--06-07');
    });

    test('parseia MonthDay valido', () {
      final parsed = parseMonthDay('--12-31');

      expect(parsed.month, 12);
      expect(parsed.day, 31);
    });

    test('rejeita MonthDay malformado', () {
      expect(() => parseMonthDay('2026-06-07'), throwsFormatException);
      expect(() => parseMonthDay('--13-01'), throwsFormatException);
    });

    test('materializa aniversario em intervalo normal', () {
      final date = materializeMonthDayInRange(
        month: 6,
        day: 7,
        start: DateTime(2026, 6),
        end: DateTime(2026, 6, 30),
      );

      expect(date, DateTime(2026, 6, 7));
    });

    test(
      'materializa aniversario em intervalo que cruza dezembro e janeiro',
      () {
        final december = materializeMonthDayInRange(
          month: 12,
          day: 31,
          start: DateTime(2026, 12, 28),
          end: DateTime(2027, 1, 3),
        );
        final january = materializeMonthDayInRange(
          month: 1,
          day: 2,
          start: DateTime(2026, 12, 28),
          end: DateTime(2027, 1, 3),
        );

        expect(december, DateTime(2026, 12, 31));
        expect(january, DateTime(2027, 1, 2));
      },
    );

    test('retorna null quando aniversario fica fora do intervalo', () {
      final date = materializeMonthDayInRange(
        month: 7,
        day: 10,
        start: DateTime(2026, 6),
        end: DateTime(2026, 6, 30),
      );

      expect(date, isNull);
    });
  });
}
