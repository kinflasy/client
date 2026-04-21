// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department_providers.dart';

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

@ProviderFor(filteredDepartments)
final filteredDepartmentsProvider = FilteredDepartmentsFamily._();

final class FilteredDepartmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DepartmentEntity>>,
          AsyncValue<List<DepartmentEntity>>,
          AsyncValue<List<DepartmentEntity>>
        >
    with $Provider<AsyncValue<List<DepartmentEntity>>> {
  FilteredDepartmentsProvider._({
    required FilteredDepartmentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredDepartmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredDepartmentsHash();

  @override
  String toString() {
    return r'filteredDepartmentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<DepartmentEntity>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<DepartmentEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredDepartments(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<DepartmentEntity>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<DepartmentEntity>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredDepartmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredDepartmentsHash() =>
    r'c657b3c840ee7408ef1b2db904f61ec081b93be9';

final class FilteredDepartmentsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<DepartmentEntity>>, String> {
  FilteredDepartmentsFamily._()
    : super(
        retry: null,
        name: r'filteredDepartmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredDepartmentsProvider call(String unitId) =>
      FilteredDepartmentsProvider._(argument: unitId, from: this);

  @override
  String toString() => r'filteredDepartmentsProvider';
}
