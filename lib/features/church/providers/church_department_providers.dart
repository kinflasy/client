import 'package:client/core/network/dio_client.dart';
import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/church/data/datasources/church_departments_api.dart';
import 'package:client/features/church/data/repositories/church_department_repository_impl.dart';
import 'package:client/features/church/data/models/department_request_model.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/repositories/church_department_repository.dart';
import 'package:client/core/errors/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'church_department_providers.g.dart';

final churchDepartmentApiProvider = Provider<ChurchDepartmentsApi>(
  (ref) => ChurchDepartmentsApi(ref.watch(dioClientProvider)),
);

final churchDepartmentRepositoryProvider = Provider<ChurchDepartmentRepository>(
  (ref) =>
      ChurchDepartmentRepositoryImpl(ref.watch(churchDepartmentApiProvider)),
);

final rawChurchDepartmentsProvider =
    FutureProvider.family<List<ChurchDepartmentEntity>, String>((
      ref,
      unitId,
    ) async {
      final result = await ref
          .read(churchDepartmentRepositoryProvider)
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
AsyncValue<List<ChurchDepartmentEntity>> filteredChurchDepartments(
  Ref ref,
  String unitId,
) {
  final rawAsync = ref.watch(rawChurchDepartmentsProvider(unitId));
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

final churchDepartmentsProvider = rawChurchDepartmentsProvider;

final registerDepartmentProvider =
    NotifierProvider<RegisterDepartmentNotifier, AsyncValue<void>>(
      RegisterDepartmentNotifier.new,
    );

class RegisterDepartmentNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, ChurchDepartmentEntity>> create(
    String unitId,
    DepartmentRequestModel request,
  ) async {
    state = const AsyncLoading();
    final result = await ref
        .read(churchDepartmentRepositoryProvider)
        .createDepartment(unitId, request);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result;
  }
}
