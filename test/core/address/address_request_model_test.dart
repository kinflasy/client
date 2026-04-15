import 'package:client/core/address/address_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AddressRequestModel serializes to backend-compatible json', () {
    const model = AddressRequestModel(
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

    expect(model.toJson(), {
      'zip': '60000-000',
      'country': 'Brasil',
      'state': 'CE',
      'city': 'Fortaleza',
      'neighborhood': 'Centro',
      'street': 'Rua A',
      'number': '123',
      'complement': 'Apto 12',
      'reference': 'Perto da praça',
    });
  });
}
