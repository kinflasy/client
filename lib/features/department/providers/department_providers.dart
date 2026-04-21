import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/data/repositories/department_repository_impl.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'department_providers.g.dart';

final departmentApiProvider = Provider<DepartmentApi>(
  (ref) => DepartmentApi(ref.watch(dioClientProvider)),
);

final departmentRepositoryProvider = Provider<DepartmentRepository>(
  (ref) => DepartmentRepositoryImpl(ref.watch(departmentApiProvider)),
);

final rawDepartmentsProvider = FutureProvider.family<List<DepartmentEntity>, String>((
      ref,
      unitId,
    ) async {
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
AsyncValue<List<DepartmentEntity>> filteredDepartments(
  Ref ref,
  String unitId,
) {
  final rawAsync = ref.watch(rawDepartmentsProvider(unitId));
  final query = ref.watch(departmentSearchQueryProvider);

  return rawAsync.whenData((departments) {
    final normalizedQuery = normalizeSearchTerm(query);

    final filtered = normalizedQuery.isEmpty
        ? [...departments]
        : departments.where((department) {
            final normalizedName = normalizeSearchTerm(department.name);
            return normalizedName.contains(normalizedQuery);
          }).toList();

    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  });
}

final departmentsProvider = rawDepartmentsProvider;

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
