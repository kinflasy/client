// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MembershipNotifier)
final membershipProvider = MembershipNotifierProvider._();

final class MembershipNotifierProvider
    extends $AsyncNotifierProvider<MembershipNotifier, List<MembershipEntity>> {
  MembershipNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipNotifierHash();

  @$internal
  @override
  MembershipNotifier create() => MembershipNotifier();
}

String _$membershipNotifierHash() =>
    r'e66e47c37d0921ea8444a17409a7aa90daa95891';

abstract class _$MembershipNotifier
    extends $AsyncNotifier<List<MembershipEntity>> {
  FutureOr<List<MembershipEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<MembershipEntity>>, List<MembershipEntity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MembershipEntity>>,
                List<MembershipEntity>
              >,
              AsyncValue<List<MembershipEntity>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(hasMembership)
final hasMembershipProvider = HasMembershipProvider._();

final class HasMembershipProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  HasMembershipProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasMembershipProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasMembershipHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasMembership(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasMembershipHash() => r'236ccf6c75c1e18e6e875def1c79d6802446f5aa';
