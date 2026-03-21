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
    extends $FunctionalProvider<Affiliation, Affiliation, Affiliation>
    with $Provider<Affiliation> {
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
  $ProviderElement<Affiliation> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Affiliation create(Ref ref) {
    return currentUserProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Affiliation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Affiliation>(value),
    );
  }
}

String _$currentUserProfileHash() =>
    r'2488cad8e4222f30b6f2383cbcdc1f66a9531f29';
