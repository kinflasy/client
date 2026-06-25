// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionPermissions)
final sessionPermissionsProvider = SessionPermissionsProvider._();

final class SessionPermissionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionPermissions>,
          SessionPermissions,
          FutureOr<SessionPermissions>
        >
    with
        $FutureModifier<SessionPermissions>,
        $FutureProvider<SessionPermissions> {
  SessionPermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionPermissionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionPermissionsHash();

  @$internal
  @override
  $FutureProviderElement<SessionPermissions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SessionPermissions> create(Ref ref) {
    return sessionPermissions(ref);
  }
}

String _$sessionPermissionsHash() =>
    r'129e2487326569ac0de5db909d3bc1ab61dae8e0';

@ProviderFor(currentUserProfile)
final currentUserProfileProvider = CurrentUserProfileProvider._();

final class CurrentUserProfileProvider
    extends $FunctionalProvider<Affiliation?, Affiliation?, Affiliation?>
    with $Provider<Affiliation?> {
  CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $ProviderElement<Affiliation?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Affiliation? create(Ref ref) {
    return currentUserProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Affiliation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Affiliation?>(value),
    );
  }
}

String _$currentUserProfileHash() =>
    r'a37e1d79bc3bf803c341d2e6dd4a95b128e15ccc';
