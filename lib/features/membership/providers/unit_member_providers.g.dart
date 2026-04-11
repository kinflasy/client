// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_member_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MemberSearchQuery)
final memberSearchQueryProvider = MemberSearchQueryProvider._();

final class MemberSearchQueryProvider
    extends $NotifierProvider<MemberSearchQuery, String> {
  MemberSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberSearchQueryHash();

  @$internal
  @override
  MemberSearchQuery create() => MemberSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$memberSearchQueryHash() => r'3019f7daa4d9558a7e2ea5a292a543851d604b0d';

abstract class _$MemberSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(rawUnitMembers)
final rawUnitMembersProvider = RawUnitMembersFamily._();

final class RawUnitMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UnitMemberEntity>>,
          List<UnitMemberEntity>,
          FutureOr<List<UnitMemberEntity>>
        >
    with
        $FutureModifier<List<UnitMemberEntity>>,
        $FutureProvider<List<UnitMemberEntity>> {
  RawUnitMembersProvider._({
    required RawUnitMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'rawUnitMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rawUnitMembersHash();

  @override
  String toString() {
    return r'rawUnitMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<UnitMemberEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UnitMemberEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return rawUnitMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RawUnitMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rawUnitMembersHash() => r'1197e24ca87b3af1906f75405145e625a7e2b971';

final class RawUnitMembersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<UnitMemberEntity>>, String> {
  RawUnitMembersFamily._()
    : super(
        retry: null,
        name: r'rawUnitMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RawUnitMembersProvider call(String unitId) =>
      RawUnitMembersProvider._(argument: unitId, from: this);

  @override
  String toString() => r'rawUnitMembersProvider';
}

@ProviderFor(filteredMembers)
final filteredMembersProvider = FilteredMembersFamily._();

final class FilteredMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UnitMemberEntity>>,
          AsyncValue<List<UnitMemberEntity>>,
          AsyncValue<List<UnitMemberEntity>>
        >
    with $Provider<AsyncValue<List<UnitMemberEntity>>> {
  FilteredMembersProvider._({
    required FilteredMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredMembersHash();

  @override
  String toString() {
    return r'filteredMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<UnitMemberEntity>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<UnitMemberEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredMembers(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<UnitMemberEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<UnitMemberEntity>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredMembersHash() => r'0c887a65a8e7372821f7ff62c226c8bef3f630d0';

final class FilteredMembersFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<UnitMemberEntity>>, String> {
  FilteredMembersFamily._()
    : super(
        retry: null,
        name: r'filteredMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredMembersProvider call(String unitId) =>
      FilteredMembersProvider._(argument: unitId, from: this);

  @override
  String toString() => r'filteredMembersProvider';
}
