import 'package:client/core/address/address_form_state.dart';
import 'package:client/features/church/presentation/screens/register_church_screen.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildChurchStarterRequest', () {
    test('returns null when address is blank', () {
      const state = RegisterChurchFormState(
        churchName: 'Igreja Central',
        churchSlug: 'igreja-central',
        churchEmail: 'contato@igreja.dev',
        unitName: 'Sede',
        unitSlug: 'sede',
        unitPhone: '1111',
        unitEmail: 'sede@igreja.dev',
      );

      expect(buildChurchStarterRequest(state), isNull);
    });

    test('builds request from shared address state', () {
      const state = RegisterChurchFormState(
        churchName: 'Igreja Central',
        churchSlug: 'igreja-central',
        churchAcronym: 'IC',
        churchPhone: '(11) 98765-4321',
        churchEmail: 'contato@igreja.dev',
        unitName: 'Sede',
        unitSlug: 'sede',
        unitPhone: '(85) 3333-4444',
        unitEmail: 'sede@igreja.dev',
        address: AddressFormState(
          zip: '60000-000',
          city: 'Fortaleza',
          state: 'CE',
          street: 'Rua A',
          number: '10',
        ),
      );

      final request = buildChurchStarterRequest(state);

      expect(request, isNotNull);
      expect(request!.name, 'Igreja Central');
      expect(request.acronym, 'IC');
      expect(request.phone, '11987654321');
      expect(request.unit.phone, '8533334444');
      expect(request.unit.address.toJson(), {
        'zip': '60000-000',
        'country': null,
        'state': 'CE',
        'city': 'Fortaleza',
        'neighborhood': null,
        'street': 'Rua A',
        'number': '10',
        'complement': null,
        'reference': null,
      });
    });
  });
}
