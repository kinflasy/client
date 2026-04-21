import 'package:client/core/domain/enums/entry_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_member_form_provider.g.dart';

class RegisterMemberFormState {
  const RegisterMemberFormState({
    this.fullName = '',
    this.nickname = '',
    this.gender,
    this.birthDate,
    this.phone = '',
    this.email = '',
    this.affiliation,
    this.entryMode,
    this.entryDate,
  });

  final String fullName;
  final String nickname;
  final String? gender;
  final DateTime? birthDate;
  final String phone;
  final String email;
  final String? affiliation;
  final EntryMode? entryMode;
  final DateTime? entryDate;

  RegisterMemberFormState copyWith({
    String? fullName,
    String? nickname,
    String? gender,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? phone,
    String? email,
    String? affiliation,
    EntryMode? entryMode,
    bool clearEntryMode = false,
    DateTime? entryDate,
    bool clearEntryDate = false,
  }) {
    return RegisterMemberFormState(
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      birthDate: clearBirthDate ? null : birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      affiliation: affiliation ?? this.affiliation,
      entryMode: clearEntryMode ? null : entryMode ?? this.entryMode,
      entryDate: clearEntryDate ? null : entryDate ?? this.entryDate,
    );
  }
}

@riverpod
class RegisterMemberFormNotifier extends _$RegisterMemberFormNotifier {
  @override
  RegisterMemberFormState build() => const RegisterMemberFormState();

  void updatePersonalData({
    String? fullName,
    String? nickname,
    String? gender,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? phone,
    String? email,
  }) {
    state = state.copyWith(
      fullName: fullName,
      nickname: nickname,
      gender: gender,
      birthDate: birthDate,
      clearBirthDate: clearBirthDate,
      phone: phone,
      email: email,
    );
  }

  void updateAffiliationData({
    String? affiliation,
    EntryMode? entryMode,
    bool clearEntryMode = false,
    DateTime? entryDate,
    bool clearEntryDate = false,
  }) {
    state = state.copyWith(
      affiliation: affiliation,
      entryMode: entryMode,
      clearEntryMode: clearEntryMode,
      entryDate: entryDate,
      clearEntryDate: clearEntryDate,
    );
  }

  void reset() {
    state = const RegisterMemberFormState();
  }
}
