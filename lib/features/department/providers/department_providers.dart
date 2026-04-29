import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/data/repositories/department_repository_impl.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'department_providers.g.dart';

class SegmentedDepartments extends Equatable {
  const SegmentedDepartments({
    required this.myDepartments,
    required this.generalDepartments,
    required this.administrativeDepartments,
  });

  final List<DepartmentEntity> myDepartments;
  final List<DepartmentEntity> generalDepartments;
  final List<DepartmentEntity> administrativeDepartments;

  @override
  List<Object?> get props => [
    myDepartments,
    generalDepartments,
    administrativeDepartments,
  ];
}

enum DepartmentCategory { my, general, administrative }

class DepartmentCategoryRequest extends Equatable {
  const DepartmentCategoryRequest({
    required this.unitId,
    required this.category,
  });

  final String unitId;
  final DepartmentCategory category;

  @override
  List<Object?> get props => [unitId, category];
}

class DepartmentCategorySearchRequest extends Equatable {
  const DepartmentCategorySearchRequest({
    required this.unitId,
    required this.category,
    required this.query,
  });

  final String unitId;
  final DepartmentCategory category;
  final String query;

  @override
  List<Object?> get props => [unitId, category, query];
}

final departmentApiProvider = Provider<DepartmentApi>(
  (ref) => DepartmentApi(ref.watch(dioClientProvider)),
);

final departmentRepositoryProvider = Provider<DepartmentRepository>(
  (ref) => DepartmentRepositoryImpl(ref.watch(departmentApiProvider)),
);

final rawDepartmentsProvider =
    FutureProvider.family<List<DepartmentEntity>, String>((ref, unitId) async {
      final result = await ref
          .read(departmentRepositoryProvider)
          .getDepartmentsByUnitId(unitId);
      return result.fold(
        (failure) => throw failure,
        (departments) => departments,
      );
    });

@riverpod
class DepartmentSearchQuery extends _$DepartmentSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}

@riverpod
AsyncValue<List<DepartmentEntity>> filteredDepartments(Ref ref, String unitId) {
  final rawAsync = ref.watch(rawDepartmentsProvider(unitId));
  final query = ref.watch(departmentSearchQueryProvider);

  return rawAsync.whenData(
    (departments) => _filterDepartmentsByQuery(departments, query),
  );
}

final departmentsProvider = rawDepartmentsProvider;

final segmentedDepartmentsProvider =
    FutureProvider.family<SegmentedDepartments, String>((ref, unitId) async {
      final departments = await ref.watch(departmentsProvider(unitId).future);
      final permissions = await ref.watch(sessionPermissionsProvider.future);
      final myDepartmentIds = permissions.integrations
          .map((item) => item.departmentId)
          .toSet();

      final administrative = <DepartmentEntity>[];
      final general = <DepartmentEntity>[];
      final mine = <DepartmentEntity>[];

      for (final department in departments) {
        if (myDepartmentIds.contains(department.id)) {
          mine.add(department);
        }

        final isAdministrative = department.type == 'ADMINISTRATIVE';
        if (isAdministrative) {
          administrative.add(department);
          continue;
        }

        general.add(department);
      }

      int byName(DepartmentEntity a, DepartmentEntity b) =>
          a.name.compareTo(b.name);

      general.sort(byName);
      administrative.sort(byName);
      mine.sort(byName);

      return SegmentedDepartments(
        myDepartments: mine,
        generalDepartments: general,
        administrativeDepartments: administrative,
      );
    });

final categoryDepartmentsProvider =
    FutureProvider.family<List<DepartmentEntity>, DepartmentCategoryRequest>((
      ref,
      request,
    ) async {
      final segmented = await ref.watch(
        segmentedDepartmentsProvider(request.unitId).future,
      );

      return _departmentsByCategory(segmented, request.category);
    });

final filteredCategoryDepartmentsProvider =
    FutureProvider.family<
      List<DepartmentEntity>,
      DepartmentCategorySearchRequest
    >((ref, request) async {
      final departments = await ref.watch(
        categoryDepartmentsProvider(
          DepartmentCategoryRequest(
            unitId: request.unitId,
            category: request.category,
          ),
        ).future,
      );

      return _filterDepartmentsByQuery(departments, request.query);
    });

final createDepartmentProvider =
    NotifierProvider<CreateDepartmentNotifier, AsyncValue<void>>(
      CreateDepartmentNotifier.new,
    );

class CreateDepartmentNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, DepartmentEntity>> create(
    String unitId,
    DepartmentRequestModel request,
  ) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .createDepartment(unitId, request);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result;
  }
}

DepartmentCategory? departmentCategoryFromPath(String value) {
  return switch (value.trim().toLowerCase()) {
    'my' => DepartmentCategory.my,
    'general' => DepartmentCategory.general,
    'administrative' => DepartmentCategory.administrative,
    _ => null,
  };
}

String departmentCategoryLabel(DepartmentCategory category) {
  return switch (category) {
    DepartmentCategory.my => 'Meus departamentos',
    DepartmentCategory.general => 'Geral',
    DepartmentCategory.administrative => 'Administrativo',
  };
}

String departmentCategoryPathValue(DepartmentCategory category) {
  return switch (category) {
    DepartmentCategory.my => 'my',
    DepartmentCategory.general => 'general',
    DepartmentCategory.administrative => 'administrative',
  };
}

List<DepartmentEntity> _departmentsByCategory(
  SegmentedDepartments segmented,
  DepartmentCategory category,
) {
  return switch (category) {
    DepartmentCategory.my => segmented.myDepartments,
    DepartmentCategory.general => segmented.generalDepartments,
    DepartmentCategory.administrative => segmented.administrativeDepartments,
  };
}

List<DepartmentEntity> _filterDepartmentsByQuery(
  List<DepartmentEntity> departments,
  String query,
) {
  final normalizedQuery = normalizeSearchTerm(query);

  final filtered = normalizedQuery.isEmpty
      ? [...departments]
      : departments.where((department) {
          final normalizedName = normalizeSearchTerm(department.name);
          return normalizedName.contains(normalizedQuery);
        }).toList();

  filtered.sort((a, b) => a.name.compareTo(b.name));
  return filtered;
}
