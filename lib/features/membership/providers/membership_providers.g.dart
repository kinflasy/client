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

@ProviderFor(MyPendingMembershipsNotifier)
final myPendingMembershipsProvider = MyPendingMembershipsNotifierProvider._();

final class MyPendingMembershipsNotifierProvider
    extends
        $AsyncNotifierProvider<
          MyPendingMembershipsNotifier,
          List<PendingMembershipEntity>
        > {
  MyPendingMembershipsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPendingMembershipsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPendingMembershipsNotifierHash();

  @$internal
  @override
  MyPendingMembershipsNotifier create() => MyPendingMembershipsNotifier();
}

String _$myPendingMembershipsNotifierHash() =>
    r'548a62e1800dd2bd9c8542b1af55657e4f317b4a';

abstract class _$MyPendingMembershipsNotifier
    extends $AsyncNotifier<List<PendingMembershipEntity>> {
  FutureOr<List<PendingMembershipEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<PendingMembershipEntity>>,
              List<PendingMembershipEntity>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PendingMembershipEntity>>,
                List<PendingMembershipEntity>
              >,
              AsyncValue<List<PendingMembershipEntity>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(pendingMembershipForUnit)
final pendingMembershipForUnitProvider = PendingMembershipForUnitFamily._();

final class PendingMembershipForUnitProvider
    extends
        $FunctionalProvider<
          PendingMembershipEntity?,
          PendingMembershipEntity?,
          PendingMembershipEntity?
        >
    with $Provider<PendingMembershipEntity?> {
  PendingMembershipForUnitProvider._({
    required PendingMembershipForUnitFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingMembershipForUnitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingMembershipForUnitHash();

  @override
  String toString() {
    return r'pendingMembershipForUnitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PendingMembershipEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingMembershipEntity? create(Ref ref) {
    final argument = this.argument as String;
    return pendingMembershipForUnit(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingMembershipEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingMembershipEntity?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PendingMembershipForUnitProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingMembershipForUnitHash() =>
    r'0838dabb792869f6079e269be13697a354ce4881';

final class PendingMembershipForUnitFamily extends $Family
    with $FunctionalFamilyOverride<PendingMembershipEntity?, String> {
  PendingMembershipForUnitFamily._()
    : super(
        retry: null,
        name: r'pendingMembershipForUnitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PendingMembershipForUnitProvider call(String unitId) =>
      PendingMembershipForUnitProvider._(argument: unitId, from: this);

  @override
  String toString() => r'pendingMembershipForUnitProvider';
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
