import 'package:client/core/address/address_form_state.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:client/features/membership/providers/edit_inactive_person_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final profile = MemberProfileEntity(
    personId: 'person-1',
    membershipId: 'membership-1',
    personType: PersonType.inactive,
    fullName: 'Maria Souza',
    nickname: 'Mari',
    gender: 'FEMALE',
    birthDate: DateTime(1995, 2, 3),
    phone: '(85) 99999-1111',
    email: 'maria@dev.com',
    addressDetails: AddressDetailsEntity(
      id: 'address-1',
      zip: '60000-000',
      country: 'Brasil',
      state: 'CE',
      city: 'Fortaleza',
      neighborhood: 'Centro',
      street: 'Rua A',
      number: '123',
      complement: 'Apto 2',
      reference: 'Perto da praca',
    ),
    affiliation: 'VISITOR',
  );

  test('initializes form state from profile including address', () {
    final state = createEditInactivePersonFormState(profile);
    expect(state.isInitialized, isTrue);
    expect(state.fullName, 'Maria Souza');
    expect(state.nickname, 'Mari');
    expect(state.address.city, 'Fortaleza');
    expect(state.address.reference, 'Perto da praca');
  });

  test('updates fields incrementally', () {
    final updated = updateEditInactivePersonFormPersonalData(
      const EditInactivePersonFormState(),
      fullName: 'Novo Nome',
      email: 'novo@dev.com',
    );
    final state = updateEditInactivePersonFormAddress(
      updated,
      city: 'Recife',
      stateCode: 'PE',
    );
    expect(state.fullName, 'Novo Nome');
    expect(state.email, 'novo@dev.com');
    expect(state.address.city, 'Recife');
    expect(state.address.state, 'PE');
  });

  test('normalizes optional blanks and empty address to null in payload', () {
    final state = EditInactivePersonFormState(
      fullName: 'Maria Souza',
      nickname: '   ',
      gender: 'FEMALE',
      birthDate: DateTime(1995, 2, 3),
      phone: ' ',
      email: '',
      address: const AddressFormState(),
      isInitialized: true,
    );

    final request = buildUpdateInactivePersonRequest(state);

    expect(request.nickname, isNull);
    expect(request.phone, isNull);
    expect(request.email, isNull);
    expect(request.address, isNull);
    expect(request.birthDate, '1995-02-03');
  });

  test('normalizes phone digits in payload', () {
    final state = EditInactivePersonFormState(
      fullName: 'Maria Souza',
      gender: 'FEMALE',
      birthDate: DateTime(1995, 2, 3),
      phone: '(85) 99999-1111',
      isInitialized: true,
    );

    final request = buildUpdateInactivePersonRequest(state);

    expect(request.phone, '85999991111');
  });
}
