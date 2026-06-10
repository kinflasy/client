import 'package:client/features/calendar/data/models/person_birthday_read_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonBirthdayReadModel', () {
    test('parseia birthday no formato MonthDay', () {
      final model = PersonBirthdayReadModel.fromJson(const {
        'id': 'person-1',
        'nickname': 'Maria',
        'birthday': '--06-07',
      });

      expect(model.id, 'person-1');
      expect(model.name, 'Maria');
      expect(model.birthdayMonth, 6);
      expect(model.birthdayDay, 7);
      expect(model.toEntity().birthdayMonth, 6);
    });

    test('usa name ou fullName quando presentes', () {
      expect(
        PersonBirthdayReadModel.fromJson(const {
          'id': 'person-1',
          'name': 'Ana',
          'birthday': '--06-07',
        }).name,
        'Ana',
      );
      expect(
        PersonBirthdayReadModel.fromJson(const {
          'id': 'person-2',
          'fullName': 'Marcos Silva',
          'birthday': '--06-08',
        }).name,
        'Marcos Silva',
      );
    });

    test('rejeita payload sem birthday', () {
      expect(
        () => PersonBirthdayReadModel.fromJson(const {
          'id': 'person-1',
          'nickname': 'Maria',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
