import 'package:client/core/address/address_form_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_church_form_provider.g.dart';

class RegisterChurchFormState {
  final String churchName;
  final String churchSlug;
  final String churchAcronym;
  final String churchPhone;
  final String churchEmail;
  final String unitName;
  final String unitSlug;
  final String unitPhone;
  final String unitEmail;
  final AddressFormState address;

  const RegisterChurchFormState({
    this.churchName = '',
    this.churchSlug = '',
    this.churchAcronym = '',
    this.churchPhone = '',
    this.churchEmail = '',
    this.unitName = '',
    this.unitSlug = '',
    this.unitPhone = '',
    this.unitEmail = '',
    this.address = const AddressFormState(),
  });

  RegisterChurchFormState copyWith({
    String? churchName,
    String? churchSlug,
    String? churchAcronym,
    String? churchPhone,
    String? churchEmail,
    String? unitName,
    String? unitSlug,
    String? unitPhone,
    String? unitEmail,
    AddressFormState? address,
  }) => RegisterChurchFormState(
    churchName: churchName ?? this.churchName,
    churchSlug: churchSlug ?? this.churchSlug,
    churchAcronym: churchAcronym ?? this.churchAcronym,
    churchPhone: churchPhone ?? this.churchPhone,
    churchEmail: churchEmail ?? this.churchEmail,
    unitName: unitName ?? this.unitName,
    unitSlug: unitSlug ?? this.unitSlug,
    unitPhone: unitPhone ?? this.unitPhone,
    unitEmail: unitEmail ?? this.unitEmail,
    address: address ?? this.address,
  );
}

@riverpod
class RegisterChurchFormNotifier extends _$RegisterChurchFormNotifier {
  @override
  RegisterChurchFormState build() => const RegisterChurchFormState();

  void update(RegisterChurchFormState Function(RegisterChurchFormState) updater) {
    state = updater(state);
  }
}
