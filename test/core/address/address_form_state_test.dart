import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/address/address_request_model.dart';
import 'package:client/core/address/address_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressFormState', () {
    test('isBlank is true for empty form', () {
      const state = AddressFormState();

      expect(state.isBlank, isTrue);
    });

    test('toRequestOrNull returns null for blank form', () {
      const state = AddressFormState();

      expect(state.toRequestOrNull(), isNull);
    });

    test('toRequestOrNull normalizes blank values to null', () {
      const state = AddressFormState(
        zip: ' 60000-000 ',
        country: ' ',
        state: ' CE ',
        city: ' Fortaleza ',
      );

      expect(
        state.toRequestOrNull(),
        const AddressRequestModel(
          zip: '60000-000',
          country: null,
          state: 'CE',
          city: 'Fortaleza',
        ),
      );
    });

    test('fromValue and toValue keep normalized address data', () {
      const value = AddressValue(
        zip: '60000-000',
        country: 'Brasil',
        state: 'CE',
        city: 'Fortaleza',
        neighborhood: 'Centro',
        street: 'Rua A',
        number: '10',
        complement: 'Sala 2',
        reference: 'Ao lado',
      );

      final state = AddressFormState.fromValue(value);

      expect(state.zip, '60000-000');
      expect(state.toValue(), value);
    });
  });
}
