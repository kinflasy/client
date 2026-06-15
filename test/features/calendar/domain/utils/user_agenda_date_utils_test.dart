import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/utils/user_agenda_date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('user agenda date utils', () {
    test('calcula semana iniciando no domingo', () {
      final date = DateTime(2026, 6, 3, 14, 30);

      expect(weekStart(date), DateTime(2026, 5, 31));
      expect(weekEnd(date), DateTime(2026, 6, 6));
    });

    test('mantem o proprio dia quando a semana comeca no domingo', () {
      final date = DateTime(2026, 5, 31, 9);

      expect(weekStart(date), DateTime(2026, 5, 31));
      expect(weekEnd(date), DateTime(2026, 6, 6));
    });

    test('calcula mes visivel que inicia no domingo', () {
      final visibleDates = visibleDatesForMonth(DateTime(2026, 2));

      expect(visibleDates.first, DateTime(2026, 2));
      expect(visibleDates.last, DateTime(2026, 2, 28));
    });

    test('calcula mes visivel que inicia no meio da semana', () {
      final visibleDates = visibleDatesForMonth(DateTime(2026, 6));

      expect(visibleDates.first, DateTime(2026, 5, 31));
      expect(visibleDates.last, DateTime(2026, 7, 4));
    });

    test('expande evento de multiplos dias em ocorrencias locais', () {
      final event = UserAgendaEventItemEntity(
        id: 'event-1',
        title: 'Congresso',
        startDateTime: _multiDayStart,
        endDateTime: _multiDayEnd,
        origin: 'Igreja Central',
      );

      final occurrences = expandItemOccurrences(event);

      expect(occurrences.map((occurrence) => occurrence.date).toList(), [
        DateTime(2026, 6, 5),
        DateTime(2026, 6, 6),
        DateTime(2026, 6, 7),
      ]);
    });

    test('repete o horario original nas ocorrencias de multiplos dias', () {
      final event = UserAgendaEventItemEntity(
        id: 'event-1',
        title: 'Congresso',
        startDateTime: _multiDayStart,
        endDateTime: _multiDayEnd,
        origin: 'Igreja Central',
      );

      final occurrences = expandItemOccurrences(event);

      expect(occurrences.map((occurrence) => occurrence.dateTime).toList(), [
        DateTime(2026, 6, 5, 19, 30),
        DateTime(2026, 6, 6, 19, 30),
        DateTime(2026, 6, 7, 19, 30),
      ]);
    });
  });
}

final _multiDayStart = DateTime(2026, 6, 5, 19, 30);
final _multiDayEnd = DateTime(2026, 6, 7, 10);
