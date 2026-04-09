// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_member_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RegisterMemberNotifier)
final registerMemberProvider = RegisterMemberNotifierProvider._();

final class RegisterMemberNotifierProvider
    extends $NotifierProvider<RegisterMemberNotifier, AsyncValue<void>> {
  RegisterMemberNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerMemberProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerMemberNotifierHash();

  @$internal
  @override
  RegisterMemberNotifier create() => RegisterMemberNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$registerMemberNotifierHash() =>
    r'7f674304b39cbbe7fb5ad0d54b959e9014acf0bd';

abstract class _$RegisterMemberNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
