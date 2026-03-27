// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_church_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RegisterChurchFormNotifier)
final registerChurchFormProvider = RegisterChurchFormNotifierProvider._();

final class RegisterChurchFormNotifierProvider
    extends
        $NotifierProvider<RegisterChurchFormNotifier, RegisterChurchFormState> {
  RegisterChurchFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerChurchFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerChurchFormNotifierHash();

  @$internal
  @override
  RegisterChurchFormNotifier create() => RegisterChurchFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegisterChurchFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegisterChurchFormState>(value),
    );
  }
}

String _$registerChurchFormNotifierHash() =>
    r'282224ea598ee8b403d45c6ca173bb45238cefc6';

abstract class _$RegisterChurchFormNotifier
    extends $Notifier<RegisterChurchFormState> {
  RegisterChurchFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<RegisterChurchFormState, RegisterChurchFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegisterChurchFormState, RegisterChurchFormState>,
              RegisterChurchFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
