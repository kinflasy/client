import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/address/address_value.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/data/models/update_inactive_person_request_model.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValue, WidgetRef;
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';

class EditInactivePersonFormState {
  const EditInactivePersonFormState({
    this.fullName = '',
    this.nickname = '',
    this.gender,
    this.birthDate,
    this.phone = '',
    this.email = '',
    this.address = const AddressFormState(),
    this.isInitialized = false,
  });

  final String fullName;
  final String nickname;
  final String? gender;
  final DateTime? birthDate;
  final String phone;
  final String email;
  final AddressFormState address;
  final bool isInitialized;

  EditInactivePersonFormState copyWith({
    String? fullName,
    String? nickname,
    String? gender,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? phone,
    String? email,
    AddressFormState? address,
    bool? isInitialized,
  }) {
    return EditInactivePersonFormState(
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      birthDate: clearBirthDate ? null : birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final editInactivePersonFormProvider = StateProvider.autoDispose
    .family<EditInactivePersonFormState, String>(
      (ref, personId) => const EditInactivePersonFormState(),
    );

final editInactivePersonSubmitProvider =
    StateProvider.autoDispose<AsyncValue<void>>(
      (ref) => const AsyncValue.data(null),
    );

void initializeEditInactivePersonForm(
  WidgetRef ref, {
  required String personId,
  required MemberProfileEntity profile,
}) {
  final controller = ref.read(
    editInactivePersonFormProvider(personId).notifier,
  );
  if (controller.state.isInitialized) return;
  controller.state = createEditInactivePersonFormState(profile);
}

void updateEditInactivePersonPersonalData(
  WidgetRef ref, {
  required String personId,
  String? fullName,
  String? nickname,
  String? gender,
  DateTime? birthDate,
  String? phone,
  String? email,
}) {
  final controller = ref.read(
    editInactivePersonFormProvider(personId).notifier,
  );
  controller.state = updateEditInactivePersonFormPersonalData(
    controller.state,
    fullName: fullName,
    nickname: nickname,
    gender: gender,
    birthDate: birthDate,
    phone: phone,
    email: email,
  );
}

void updateEditInactivePersonAddress(
  WidgetRef ref, {
  required String personId,
  String? zip,
  String? country,
  String? stateCode,
  String? city,
  String? neighborhood,
  String? street,
  String? number,
  String? complement,
  String? reference,
}) {
  final controller = ref.read(
    editInactivePersonFormProvider(personId).notifier,
  );
  controller.state = updateEditInactivePersonFormAddress(
    controller.state,
    zip: zip,
    country: country,
    stateCode: stateCode,
    city: city,
    neighborhood: neighborhood,
    street: street,
    number: number,
    complement: complement,
    reference: reference,
  );
}

EditInactivePersonFormState createEditInactivePersonFormState(
  MemberProfileEntity profile,
) {
  final address = profile.addressDetails;
  return EditInactivePersonFormState(
    fullName: profile.fullName,
    nickname: profile.nickname ?? '',
    gender: profile.gender,
    birthDate: profile.birthDate,
    phone: profile.phone ?? '',
    email: profile.email ?? '',
    address: AddressFormState.fromValue(
      address?.toValue() ?? const AddressValue.empty(),
    ),
    isInitialized: true,
  );
}

EditInactivePersonFormState updateEditInactivePersonFormPersonalData(
  EditInactivePersonFormState current, {
  String? fullName,
  String? nickname,
  String? gender,
  DateTime? birthDate,
  String? phone,
  String? email,
}) {
  return current.copyWith(
    fullName: fullName,
    nickname: nickname,
    gender: gender,
    birthDate: birthDate,
    phone: phone,
    email: email,
    isInitialized: true,
  );
}

EditInactivePersonFormState updateEditInactivePersonFormAddress(
  EditInactivePersonFormState current, {
  String? zip,
  String? country,
  String? stateCode,
  String? city,
  String? neighborhood,
  String? street,
  String? number,
  String? complement,
  String? reference,
}) {
  return current.copyWith(
    address: current.address.copyWith(
      zip: zip,
      country: country,
      state: stateCode,
      city: city,
      neighborhood: neighborhood,
      street: street,
      number: number,
      complement: complement,
      reference: reference,
    ),
    isInitialized: true,
  );
}

Future<Either<Failure, void>> submitEditInactivePerson(
  WidgetRef ref, {
  required String personId,
  required UpdateInactivePersonRequestModel request,
}) async {
  ref.read(editInactivePersonSubmitProvider.notifier).state =
      const AsyncValue.loading();

  final result = await ref
      .read(memberProfileRepositoryProvider)
      .updateInactivePerson(personId: personId, request: request);

  ref.read(editInactivePersonSubmitProvider.notifier).state = result.fold(
    (failure) => AsyncValue.error(failure, StackTrace.current),
    (_) => const AsyncValue.data(null),
  );

  return result;
}

UpdateInactivePersonRequestModel buildUpdateInactivePersonRequest(
  EditInactivePersonFormState state,
) {
  return UpdateInactivePersonRequestModel(
    fullName: state.fullName.trim(),
    nickname: _nullIfBlank(state.nickname),
    gender: state.gender!,
    birthDate: _formatApiDate(state.birthDate!),
    phone: _nullIfBlank(state.phone),
    email: _nullIfBlank(state.email),
    address: state.address.toRequestOrNull(),
  );
}

Future<void> invalidateInactivePersonEditDependencies(
  WidgetRef ref, {
  required String personId,
}) async {
  final membership = await ref.read(activeMembershipProvider.future);
  final unitId = membership?.unitId;

  ref.invalidate(memberProfileProvider(personId));
  if (unitId != null && unitId.isNotEmpty) {
    ref.invalidate(rawUnitMembersProvider(unitId));
  }
}

String _formatApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String? _nullIfBlank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
