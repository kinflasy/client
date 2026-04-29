import 'package:client/core/address/address_value.dart';
import 'package:client/core/address/address_form_state.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final profile = LoggedUserProfileEntity(
    id: 'user-1',
    fullName: 'Lisa Silva',
    nickname: 'Lisa',
    email: 'lisa@example.com',
    phone: '(85) 99999-1111',
    gender: 'FEMALE',
    birthDate: DateTime(1998, 4, 9),
    address: const AddressValue(city: 'Fortaleza'),
  );

  test('initializes form state from detailed logged user profile', () {
    final state = createEditLoggedUserFormStateFromProfile(profile);

    expect(state.isInitialized, isTrue);
    expect(state.fullName, 'Lisa Silva');
    expect(state.nickname, 'Lisa');
    expect(state.email, 'lisa@example.com');
    expect(state.phone, '(85) 99999-1111');
    expect(state.address.city, 'Fortaleza');
  });

  test('updates fields incrementally', () {
    final updated = updateEditLoggedUserFormPersonalData(
      const EditLoggedUserFormState(),
      fullName: 'Novo Nome',
      email: 'novo@example.com',
    );

    expect(updated.fullName, 'Novo Nome');
    expect(updated.email, 'novo@example.com');
    expect(updated.isInitialized, isTrue);
  });

  test('normalizes optional blanks and empty address to null in payload', () {
    final request = buildUpdateLoggedUserRequest(
      EditLoggedUserFormState(
        fullName: 'Lisa Silva',
        nickname: '   ',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
        phone: ' ',
        email: '',
        address: AddressFormState(),
        isInitialized: true,
      ),
    );

    expect(request.nickname, isNull);
    expect(request.phone, isNull);
    expect(request.email, isNull);
    expect(request.address, isNull);
    expect(request.birthDate, '1998-04-09');
  });
}
