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
  final String zip;
  final String country;
  final String state;
  final String city;
  final String neighborhood;
  final String street;
  final String number;
  final String complement;
  final String reference;

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
    this.zip = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.neighborhood = '',
    this.street = '',
    this.number = '',
    this.complement = '',
    this.reference = '',
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
    String? zip,
    String? country,
    String? state,
    String? city,
    String? neighborhood,
    String? street,
    String? number,
    String? complement,
    String? reference,
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
    zip: zip ?? this.zip,
    country: country ?? this.country,
    state: state ?? this.state,
    city: city ?? this.city,
    neighborhood: neighborhood ?? this.neighborhood,
    street: street ?? this.street,
    number: number ?? this.number,
    complement: complement ?? this.complement,
    reference: reference ?? this.reference,
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