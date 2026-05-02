import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValue, FutureProvider, Provider, Ref, WidgetRef;
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/address/address_form_state.dart';
import '../../../core/address/address_request_model.dart';
import '../../../core/errors/failure.dart';
import '../data/models/church_request_model.dart';
import '../domain/entities/church_entity.dart';
import '../domain/entities/church_link_entity.dart';
import '../domain/entities/church_unit_entity.dart';
import '../domain/entities/current_church_profile_entity.dart';
import 'church_providers.dart';

class EditChurchUnitInfoFormState {
  const EditChurchUnitInfoFormState({
    this.name = '',
    this.slug = '',
    this.phone = '',
    this.email = '',
    this.address = const AddressFormState(),
    this.isInitialized = false,
  });

  final String name;
  final String slug;
  final String phone;
  final String email;
  final AddressFormState address;
  final bool isInitialized;

  EditChurchUnitInfoFormState copyWith({
    String? name,
    String? slug,
    String? phone,
    String? email,
    AddressFormState? address,
    bool? isInitialized,
  }) {
    return EditChurchUnitInfoFormState(
      name: name ?? this.name,
      slug: slug ?? this.slug,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final editChurchUnitInfoFormProvider =
    StateProvider.autoDispose<EditChurchUnitInfoFormState>(
      (ref) => const EditChurchUnitInfoFormState(),
    );

final editChurchUnitInfoSubmitProvider =
    StateProvider.autoDispose<AsyncValue<void>>(
      (ref) => const AsyncValue.data(null),
    );

final editChurchUnitGeneralInfoSubmitProvider =
    StateProvider.autoDispose<AsyncValue<void>>(
      (ref) => const AsyncValue.data(null),
    );

final unitLinksProvider = FutureProvider.family<List<ChurchLinkEntity>, String>(
  (ref, unitId) async {
    final result = await ref
        .read(churchUnitRepositoryProvider)
        .getUnitLinks(unitId);
    return result.fold((failure) => throw failure, (links) => links);
  },
);

final churchGeneralInfoActionsProvider = Provider<ChurchGeneralInfoActions>(
  ChurchGeneralInfoActions.new,
);

class ChurchGeneralInfoActions {
  const ChurchGeneralInfoActions(this._ref);

  final Ref _ref;

  Future<Either<Failure, ChurchUnitEntity>> updateUnitGeneralInfo({
    required ChurchUnitEntity currentUnit,
    required String name,
    required String slug,
    required String phone,
    required String email,
    required AddressRequestModel address,
  }) async {
    _ref.read(editChurchUnitGeneralInfoSubmitProvider.notifier).state =
        const AsyncValue.loading();

    final request = buildUpdateUnitRequest(
      currentUnit: currentUnit,
      name: name,
      slug: slug,
      phone: phone,
      email: email,
      address: address,
    );
    final result = await _ref
        .read(churchUnitRepositoryProvider)
        .updateUnit(currentUnit.id, request);

    result.fold(
      (failure) {
        _ref.read(editChurchUnitGeneralInfoSubmitProvider.notifier).state =
            AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        _ref.read(editChurchUnitGeneralInfoSubmitProvider.notifier).state =
            const AsyncValue.data(null);
        _ref.invalidate(currentChurchProfileProvider);
        _ref.invalidate(publicChurchUnitProfileProvider(currentUnit.id));
        _ref.invalidate(headquarterUnitByChurchProvider(currentUnit.churchId));
      },
    );

    return result;
  }
}

UnitRequestModel buildUpdateUnitRequest({
  required ChurchUnitEntity currentUnit,
  required String name,
  required String slug,
  required String phone,
  required String email,
  required AddressRequestModel address,
}) {
  return UnitRequestModel(
    name: name,
    slug: slug,
    phone: phone,
    email: email,
    type: currentUnit.type ?? 'MAIN',
    address: address,
  );
}

void initializeEditChurchUnitInfoForm(
  WidgetRef ref,
  ChurchUnitEntity unit, {
  ChurchEntity? fallbackChurch,
}) {
  final controller = ref.read(editChurchUnitInfoFormProvider.notifier);
  if (controller.state.isInitialized) return;
  controller.state = createEditChurchUnitInfoFormStateFromUnit(
    unit,
    fallbackChurch: fallbackChurch,
  );
}

void initializeEditChurchUnitInfoFormFromProfile(
  WidgetRef ref,
  CurrentChurchProfileEntity profile,
) {
  initializeEditChurchUnitInfoForm(
    ref,
    profile.unit,
    fallbackChurch: profile.church,
  );
}

EditChurchUnitInfoFormState createEditChurchUnitInfoFormStateFromUnit(
  ChurchUnitEntity unit, {
  ChurchEntity? fallbackChurch,
}) {
  return EditChurchUnitInfoFormState(
    name: _firstNonBlank(unit.name, fallbackChurch?.name),
    slug: _firstNonBlank(unit.slug, fallbackChurch?.slug),
    phone: _firstNonBlank(unit.phone, fallbackChurch?.phone),
    email: _firstNonBlank(unit.email, fallbackChurch?.email),
    address: AddressFormState.fromValue(unit.addressValue),
    isInitialized: true,
  );
}

String _firstNonBlank(String? primary, String? fallback) {
  final primaryValue = primary?.trim();
  if (primaryValue != null && primaryValue.isNotEmpty) return primaryValue;

  final fallbackValue = fallback?.trim();
  if (fallbackValue != null && fallbackValue.isNotEmpty) return fallbackValue;

  return '';
}

UnitRequestModel buildEditChurchUnitInfoRequest(
  EditChurchUnitInfoFormState state,
  ChurchUnitEntity currentUnit,
) {
  final address =
      state.address.toRequestOrNull() ?? const AddressRequestModel();
  return UnitRequestModel(
    name: state.name,
    slug: state.slug,
    phone: state.phone,
    email: state.email,
    type: currentUnit.type ?? 'MAIN',
    address: address,
  );
}

Future<Either<Failure, ChurchUnitEntity>> submitEditChurchUnitInfo(
  WidgetRef ref, {
  required UnitRequestModel request,
  required ChurchUnitEntity currentUnit,
}) async {
  ref.read(editChurchUnitInfoSubmitProvider.notifier).state =
      const AsyncValue.loading();

  final result = await ref
      .read(churchUnitRepositoryProvider)
      .updateUnit(currentUnit.id, request);

  result.fold(
    (failure) {
      ref.read(editChurchUnitInfoSubmitProvider.notifier).state =
          AsyncValue.error(failure, StackTrace.current);
    },
    (_) {
      ref.read(editChurchUnitInfoSubmitProvider.notifier).state =
          const AsyncValue.data(null);
      ref.invalidate(currentChurchProfileProvider);
      ref.invalidate(publicChurchUnitProfileProvider(currentUnit.id));
      ref.invalidate(headquarterUnitByChurchProvider(currentUnit.churchId));
    },
  );

  return result;
}

// ============================================================================
// Separate providers for Identity and Address editing
// ============================================================================

class EditChurchUnitIdentityFormState {
  const EditChurchUnitIdentityFormState({
    this.name = '',
    this.slug = '',
    this.phone = '',
    this.email = '',
    this.isInitialized = false,
  });

  final String name;
  final String slug;
  final String phone;
  final String email;
  final bool isInitialized;

  EditChurchUnitIdentityFormState copyWith({
    String? name,
    String? slug,
    String? phone,
    String? email,
    bool? isInitialized,
  }) {
    return EditChurchUnitIdentityFormState(
      name: name ?? this.name,
      slug: slug ?? this.slug,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final editChurchUnitIdentityFormProvider =
    StateProvider.autoDispose<EditChurchUnitIdentityFormState>(
      (ref) => const EditChurchUnitIdentityFormState(),
    );

final editChurchUnitIdentitySubmitProvider =
    StateProvider.autoDispose<AsyncValue<void>>(
      (ref) => const AsyncValue.data(null),
    );

void initializeEditChurchUnitIdentityForm(
  WidgetRef ref,
  ChurchUnitEntity unit, {
  ChurchEntity? fallbackChurch,
}) {
  final controller = ref.read(editChurchUnitIdentityFormProvider.notifier);
  if (controller.state.isInitialized) return;
  controller.state = createEditChurchUnitIdentityFormStateFromUnit(
    unit,
    fallbackChurch: fallbackChurch,
  );
}

void initializeEditChurchUnitIdentityFormFromProfile(
  WidgetRef ref,
  CurrentChurchProfileEntity profile,
) {
  initializeEditChurchUnitIdentityForm(
    ref,
    profile.unit,
    fallbackChurch: profile.church,
  );
}

EditChurchUnitIdentityFormState createEditChurchUnitIdentityFormStateFromUnit(
  ChurchUnitEntity unit, {
  ChurchEntity? fallbackChurch,
}) {
  return EditChurchUnitIdentityFormState(
    name: _firstNonBlank(unit.name, fallbackChurch?.name),
    slug: _firstNonBlank(unit.slug, fallbackChurch?.slug),
    phone: _firstNonBlank(unit.phone, fallbackChurch?.phone),
    email: _firstNonBlank(unit.email, fallbackChurch?.email),
    isInitialized: true,
  );
}

UnitRequestModel buildEditChurchUnitIdentityRequest(
  EditChurchUnitIdentityFormState state,
  ChurchUnitEntity currentUnit,
) {
  // Preserve current address if available
  return UnitRequestModel(
    name: state.name,
    slug: state.slug,
    phone: state.phone,
    email: state.email,
    type: currentUnit.type ?? 'MAIN',
    address: AddressFormState.fromValue(currentUnit.addressValue)
            .toRequestOrNull() ??
        const AddressRequestModel(),
  );
}

Future<Either<Failure, ChurchUnitEntity>> submitEditChurchUnitIdentity(
  WidgetRef ref, {
  required UnitRequestModel request,
  required ChurchUnitEntity currentUnit,
}) async {
  ref.read(editChurchUnitIdentitySubmitProvider.notifier).state =
      const AsyncValue.loading();

  final result = await ref
      .read(churchUnitRepositoryProvider)
      .updateUnit(currentUnit.id, request);

  result.fold(
    (failure) {
      ref.read(editChurchUnitIdentitySubmitProvider.notifier).state =
          AsyncValue.error(failure, StackTrace.current);
    },
    (_) {
      ref.read(editChurchUnitIdentitySubmitProvider.notifier).state =
          const AsyncValue.data(null);
      ref.invalidate(currentChurchProfileProvider);
      ref.invalidate(publicChurchUnitProfileProvider(currentUnit.id));
      ref.invalidate(headquarterUnitByChurchProvider(currentUnit.churchId));
    },
  );

  return result;
}

// ============================================================================

class EditChurchUnitAddressFormState {
  const EditChurchUnitAddressFormState({
    this.address = const AddressFormState(),
    this.isInitialized = false,
  });

  final AddressFormState address;
  final bool isInitialized;

  EditChurchUnitAddressFormState copyWith({
    AddressFormState? address,
    bool? isInitialized,
  }) {
    return EditChurchUnitAddressFormState(
      address: address ?? this.address,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final editChurchUnitAddressFormProvider =
    StateProvider.autoDispose<EditChurchUnitAddressFormState>(
      (ref) => const EditChurchUnitAddressFormState(),
    );

final editChurchUnitAddressSubmitProvider =
    StateProvider.autoDispose<AsyncValue<void>>(
      (ref) => const AsyncValue.data(null),
    );

void initializeEditChurchUnitAddressForm(
  WidgetRef ref,
  ChurchUnitEntity unit,
) {
  final controller = ref.read(editChurchUnitAddressFormProvider.notifier);
  if (controller.state.isInitialized) return;
  controller.state = EditChurchUnitAddressFormState(
    address: AddressFormState.fromValue(unit.addressValue),
    isInitialized: true,
  );
}

void initializeEditChurchUnitAddressFormFromProfile(
  WidgetRef ref,
  CurrentChurchProfileEntity profile,
) {
  initializeEditChurchUnitAddressForm(ref, profile.unit);
}

UnitRequestModel buildEditChurchUnitAddressRequest(
  EditChurchUnitAddressFormState state,
  ChurchUnitEntity currentUnit,
) {
  final address =
      state.address.toRequestOrNull() ?? const AddressRequestModel();
  return UnitRequestModel(
    name: currentUnit.name ?? '',
    slug: currentUnit.slug ?? '',
    phone: currentUnit.phone ?? '',
    email: currentUnit.email ?? '',
    type: currentUnit.type ?? 'MAIN',
    address: address,
  );
}

Future<Either<Failure, ChurchUnitEntity>> submitEditChurchUnitAddress(
  WidgetRef ref, {
  required UnitRequestModel request,
  required ChurchUnitEntity currentUnit,
}) async {
  ref.read(editChurchUnitAddressSubmitProvider.notifier).state =
      const AsyncValue.loading();

  final result = await ref
      .read(churchUnitRepositoryProvider)
      .updateUnit(currentUnit.id, request);

  result.fold(
    (failure) {
      ref.read(editChurchUnitAddressSubmitProvider.notifier).state =
          AsyncValue.error(failure, StackTrace.current);
    },
    (_) {
      ref.read(editChurchUnitAddressSubmitProvider.notifier).state =
          const AsyncValue.data(null);
      ref.invalidate(currentChurchProfileProvider);
      ref.invalidate(publicChurchUnitProfileProvider(currentUnit.id));
      ref.invalidate(headquarterUnitByChurchProvider(currentUnit.churchId));
    },
  );

  return result;
}
