// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_member_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RegisterMemberFormNotifier)
final registerMemberFormProvider = RegisterMemberFormNotifierProvider._();

final class RegisterMemberFormNotifierProvider
    extends
        $NotifierProvider<RegisterMemberFormNotifier, RegisterMemberFormState> {
  RegisterMemberFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerMemberFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerMemberFormNotifierHash();

  @$internal
  @override
  RegisterMemberFormNotifier create() => RegisterMemberFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegisterMemberFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegisterMemberFormState>(value),
    );
  }
}

String _$registerMemberFormNotifierHash() =>
    r'80764263a8e9754441ac5d76deea4554282c5b03';

abstract class _$RegisterMemberFormNotifier
    extends $Notifier<RegisterMemberFormState> {
  RegisterMemberFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<RegisterMemberFormState, RegisterMemberFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegisterMemberFormState, RegisterMemberFormState>,
              RegisterMemberFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
