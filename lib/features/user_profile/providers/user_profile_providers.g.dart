// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentUserProfile)
final currentUserProfileProvider = CurrentUserProfileProvider._();

final class CurrentUserProfileProvider
    extends $FunctionalProvider<UserProfile, UserProfile, UserProfile>
    with $Provider<UserProfile> {
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
  $ProviderElement<UserProfile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserProfile create(Ref ref) {
    return currentUserProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfile>(value),
    );
  }
}

String _$currentUserProfileHash() =>
    r'3922e64f6e5270b7bb250ccddca55a380bff1919';
