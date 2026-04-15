import 'package:client/core/address/address_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressValue', () {
    test('isBlank is true when all fields are null or blank', () {
      const value = AddressValue(zip: '  ', city: '');

      expect(value.isBlank, isTrue);
    });

    test('format returns formatted address for complete values', () {
      const value = AddressValue(
        zip: '60000-000',
        country: 'Brasil',
        state: 'CE',
        city: 'Fortaleza',
        neighborhood: 'Centro',
        street: 'Rua A',
        number: '123',
        complement: 'Apto 12',
        reference: 'Perto da praça',
      );

      expect(
        value.format(),
        'Rua A, 123, Centro, Fortaleza, CE, Brasil | Apto 12 - Perto da praça - 60000-000',
      );
    });

    test('format returns partial address without empty separators', () {
      const value = AddressValue(
        street: 'Rua B',
        city: 'Fortaleza',
        state: 'CE',
      );

      expect(value.format(), 'Rua B, Fortaleza, CE');
    });

    test('format returns null when address is blank', () {
      const value = AddressValue.empty();

      expect(value.format(), isNull);
    });
  });
}
