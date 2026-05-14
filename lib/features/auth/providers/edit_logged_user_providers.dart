import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/address/address_value.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/data/models/logged_user_profile_model.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValue, FutureProvider, Provider, Ref, WidgetRef;
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';

class EditLoggedUserFormState {
  const EditLoggedUserFormState({
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

  EditLoggedUserFormState copyWith({
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
    return EditLoggedUserFormState(
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

final editLoggedUserFormProvider =
    StateProvider.autoDispose<EditLoggedUserFormState>(
      (ref) => const EditLoggedUserFormState(),
    );

final editLoggedUserSubmitProvider =
    StateProvider.autoDispose<AsyncValue<void>>(
      (ref) => const AsyncValue.data(null),
    );

final loggedUserProfileImageSubmitProvider =
    StateProvider.autoDispose<AsyncValue<void>>(
      (ref) => const AsyncValue.data(null),
    );

final editLoggedUserActionsProvider = Provider<EditLoggedUserActions>(
  EditLoggedUserActions.new,
);

final editLoggedUserInitialDataProvider =
    FutureProvider.autoDispose<LoggedUserProfileEntity>((ref) async {
      final authenticatedUser = await ref.watch(authProvider.future);
      if (authenticatedUser == null) {
        throw const AuthFailure(
          'Não foi possível identificar o usuário autenticado.',
        );
      }

      return resolveLoggedUserProfile(ref, authenticatedUser);
    });

void initializeEditLoggedUserFormFromProfile(
  WidgetRef ref,
  LoggedUserProfileEntity profile,
) {
  final controller = ref.read(editLoggedUserFormProvider.notifier);
  if (controller.state.isInitialized) return;
  controller.state = createEditLoggedUserFormStateFromProfile(profile);
}

void updateEditLoggedUserPersonalData(
  WidgetRef ref, {
  String? fullName,
  String? nickname,
  String? gender,
  DateTime? birthDate,
  bool clearBirthDate = false,
  String? phone,
  String? email,
}) {
  final controller = ref.read(editLoggedUserFormProvider.notifier);
  controller.state = updateEditLoggedUserFormPersonalData(
    controller.state,
    fullName: fullName,
    nickname: nickname,
    gender: gender,
    birthDate: birthDate,
    clearBirthDate: clearBirthDate,
    phone: phone,
    email: email,
  );
}

EditLoggedUserFormState createEditLoggedUserFormStateFromProfile(
  LoggedUserProfileEntity profile,
) {
  return EditLoggedUserFormState(
    fullName: profile.fullName,
    nickname: profile.nickname ?? '',
    gender: profile.gender.isEmpty ? null : profile.gender,
    birthDate: profile.birthDate,
    phone: profile.phone ?? '',
    email: profile.email ?? '',
    address: AddressFormState.fromValue(profile.address),
    isInitialized: true,
  );
}

EditLoggedUserFormState updateEditLoggedUserFormPersonalData(
  EditLoggedUserFormState current, {
  String? fullName,
  String? nickname,
  String? gender,
  DateTime? birthDate,
  bool clearBirthDate = false,
  String? phone,
  String? email,
}) {
  return current.copyWith(
    fullName: fullName,
    nickname: nickname,
    gender: gender,
    birthDate: birthDate,
    clearBirthDate: clearBirthDate,
    phone: phone,
    email: email,
    isInitialized: true,
  );
}

UpdateLoggedUserRequestModel buildUpdateLoggedUserRequest(
  EditLoggedUserFormState state,
) {
  return UpdateLoggedUserRequestModel(
    fullName: state.fullName.trim(),
    nickname: _nullIfBlank(state.nickname),
    gender: state.gender!,
    birthDate: _formatApiDate(state.birthDate!),
    phone: _nullIfBlank(normalizePhone(state.phone)),
    email: _nullIfBlank(state.email),
    address: state.address.toRequestOrNull(),
  );
}

Future<Either<Failure, void>> submitEditLoggedUser(
  WidgetRef ref, {
  required UpdateLoggedUserRequestModel request,
}) async {
  ref.read(editLoggedUserSubmitProvider.notifier).state =
      const AsyncValue.loading();

  final result = await ref
      .read(authProvider.notifier)
      .updateLoggedUser(request);

  ref.read(editLoggedUserSubmitProvider.notifier).state = result.fold(
    (failure) => AsyncValue.error(failure, StackTrace.current),
    (_) => const AsyncValue.data(null),
  );

  if (result.isRight()) {
    ref.invalidate(editLoggedUserInitialDataProvider);
  }

  return result.fold(Left.new, (_) => const Right(null));
}

Future<Either<Failure, UserEntity>> updateLoggedUserProfileImage(
  WidgetRef ref, {
  required String filePath,
}) {
  return ref
      .read(editLoggedUserActionsProvider)
      .updateLoggedUserProfileImage(filePath);
}

Future<Either<Failure, void>> deleteLoggedUserProfileImage(WidgetRef ref) {
  return ref.read(editLoggedUserActionsProvider).deleteLoggedUserProfileImage();
}

class EditLoggedUserActions {
  const EditLoggedUserActions(this._ref);

  final Ref _ref;

  Future<Either<Failure, UserEntity>> updateLoggedUserProfileImage(
    String filePath,
  ) async {
    _ref.read(loggedUserProfileImageSubmitProvider.notifier).state =
        const AsyncValue.loading();

    final result = await _ref
        .read(authProvider.notifier)
        .updateLoggedUserProfileImage(filePath);

    result.fold(
      (failure) {
        _ref.read(loggedUserProfileImageSubmitProvider.notifier).state =
            AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        _ref.read(loggedUserProfileImageSubmitProvider.notifier).state =
            const AsyncValue.data(null);
        _ref.invalidate(editLoggedUserInitialDataProvider);
      },
    );

    return result;
  }

  Future<Either<Failure, void>> deleteLoggedUserProfileImage() async {
    _ref.read(loggedUserProfileImageSubmitProvider.notifier).state =
        const AsyncValue.loading();

    final result = await _ref
        .read(authRepositoryProvider)
        .deleteLoggedUserProfileImage();

    result.fold(
      (failure) {
        _ref.read(loggedUserProfileImageSubmitProvider.notifier).state =
            AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        _ref.read(loggedUserProfileImageSubmitProvider.notifier).state =
            const AsyncValue.data(null);
        _ref.invalidate(authProvider);
        _ref.invalidate(editLoggedUserInitialDataProvider);
      },
    );

    return result;
  }
}

Future<LoggedUserProfileEntity> resolveLoggedUserProfile(
  Ref ref,
  UserEntity authenticatedUser,
) async {
  final dio = ref.read(dioClientProvider);

  try {
    final profileResponse = await dio.get<Map<String, dynamic>>(
      '/v1/core/people/${authenticatedUser.id}',
    );
    final profileJson = profileResponse.data ?? <String, dynamic>{};
    final profile = LoggedUserProfileModel.fromJson(profileJson);
    final address = await _loadAddress(dio, profile.addressId);
    return _mergeLoggedUserProfile(
      authenticatedUser,
      profile.toEntity(address: address),
    );
  } on DioException {
    return _fallbackLoggedUserProfile(authenticatedUser);
  } on FormatException {
    return _fallbackLoggedUserProfile(authenticatedUser);
  } catch (_) {
    return _fallbackLoggedUserProfile(authenticatedUser);
  }
}

Future<AddressValue> _loadAddress(Dio dio, String? addressId) async {
  if (addressId == null || addressId.isEmpty) {
    return const AddressValue.empty();
  }

  try {
    final addressResponse = await dio.get<Map<String, dynamic>>(
      '/v1/core/addresses/$addressId',
    );
    final addressJson = addressResponse.data ?? <String, dynamic>{};
    return AddressValue(
      zip: addressJson['zip']?.toString(),
      country: addressJson['country']?.toString(),
      state: addressJson['state']?.toString(),
      city: addressJson['city']?.toString(),
      neighborhood: addressJson['neighborhood']?.toString(),
      street: addressJson['street']?.toString(),
      number: addressJson['number']?.toString(),
      complement: addressJson['complement']?.toString(),
      reference: addressJson['reference']?.toString(),
    );
  } catch (_) {
    return const AddressValue.empty();
  }
}

LoggedUserProfileEntity _fallbackLoggedUserProfile(UserEntity user) {
  return LoggedUserProfileEntity(
    id: user.id,
    fullName: user.fullName ?? '',
    nickname: user.nickname,
    gender: user.gender ?? '',
    birthDate: user.birthDate,
    phone: user.phone,
    email: user.email,
    profileImageId: user.profileImageId,
  );
}

LoggedUserProfileEntity _mergeLoggedUserProfile(
  UserEntity user,
  LoggedUserProfileEntity profile,
) {
  return LoggedUserProfileEntity(
    id: profile.id,
    fullName: profile.fullName.isNotEmpty
        ? profile.fullName
        : (user.fullName ?? ''),
    nickname: (profile.nickname?.trim().isNotEmpty ?? false)
        ? profile.nickname
        : user.nickname,
    gender: profile.gender.isNotEmpty ? profile.gender : (user.gender ?? ''),
    birthDate: profile.birthDate ?? user.birthDate,
    phone: (profile.phone?.trim().isNotEmpty ?? false)
        ? profile.phone
        : user.phone,
    email: (profile.email?.trim().isNotEmpty ?? false)
        ? profile.email
        : user.email,
    address: profile.address,
    profileImageId: (profile.profileImageId?.trim().isNotEmpty ?? false)
        ? profile.profileImageId
        : user.profileImageId,
  );
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
