// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activate_member_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserByUsernameLookup)
final userByUsernameLookupProvider = UserByUsernameLookupProvider._();

final class UserByUsernameLookupProvider
    extends
        $NotifierProvider<
          UserByUsernameLookup,
          AsyncValue<ActivationUserEntity?>
        > {
  UserByUsernameLookupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userByUsernameLookupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userByUsernameLookupHash();

  @$internal
  @override
  UserByUsernameLookup create() => UserByUsernameLookup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ActivationUserEntity?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ActivationUserEntity?>>(
        value,
      ),
    );
  }
}

String _$userByUsernameLookupHash() =>
    r'6631093a7ba8fa1bd3c9397f5a75f9576ae0dcbb';

abstract class _$UserByUsernameLookup
    extends $Notifier<AsyncValue<ActivationUserEntity?>> {
  AsyncValue<ActivationUserEntity?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ActivationUserEntity?>,
              AsyncValue<ActivationUserEntity?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ActivationUserEntity?>,
                AsyncValue<ActivationUserEntity?>
              >,
              AsyncValue<ActivationUserEntity?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ActivateMember)
final activateMemberProvider = ActivateMemberProvider._();

final class ActivateMemberProvider
    extends $NotifierProvider<ActivateMember, AsyncValue<void>> {
  ActivateMemberProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activateMemberProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activateMemberHash();

  @$internal
  @override
  ActivateMember create() => ActivateMember();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$activateMemberHash() => r'780035415956a878dfb5c1e6411e04fafbb7060a';

abstract class _$ActivateMember extends $Notifier<AsyncValue<void>> {
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
