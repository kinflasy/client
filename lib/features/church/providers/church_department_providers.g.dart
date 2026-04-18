// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'church_department_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DepartmentSearchQuery)
final departmentSearchQueryProvider = DepartmentSearchQueryProvider._();

final class DepartmentSearchQueryProvider
    extends $NotifierProvider<DepartmentSearchQuery, String> {
  DepartmentSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'departmentSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$departmentSearchQueryHash();

  @$internal
  @override
  DepartmentSearchQuery create() => DepartmentSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$departmentSearchQueryHash() =>
    r'f7cc2858492fce8ae798f59151a4a62c6f41bd3c';

abstract class _$DepartmentSearchQuery extends $Notifier<String> {
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

@ProviderFor(filteredChurchDepartments)
final filteredChurchDepartmentsProvider = FilteredChurchDepartmentsFamily._();

final class FilteredChurchDepartmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChurchDepartmentEntity>>,
          AsyncValue<List<ChurchDepartmentEntity>>,
          AsyncValue<List<ChurchDepartmentEntity>>
        >
    with $Provider<AsyncValue<List<ChurchDepartmentEntity>>> {
  FilteredChurchDepartmentsProvider._({
    required FilteredChurchDepartmentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredChurchDepartmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredChurchDepartmentsHash();

  @override
  String toString() {
    return r'filteredChurchDepartmentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<ChurchDepartmentEntity>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<ChurchDepartmentEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredChurchDepartments(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<ChurchDepartmentEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<ChurchDepartmentEntity>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredChurchDepartmentsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredChurchDepartmentsHash() =>
    r'a9d675cac6eda5d6e3362fd072db1da6b6abc3cd';

final class FilteredChurchDepartmentsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<List<ChurchDepartmentEntity>>,
          String
        > {
  FilteredChurchDepartmentsFamily._()
    : super(
        retry: null,
        name: r'filteredChurchDepartmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredChurchDepartmentsProvider call(String unitId) =>
      FilteredChurchDepartmentsProvider._(argument: unitId, from: this);

  @override
  String toString() => r'filteredChurchDepartmentsProvider';
}
