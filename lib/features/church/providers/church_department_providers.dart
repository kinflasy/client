import 'package:client/core/network/dio_client.dart';
import 'package:client/features/church/data/datasources/church_departments_api.dart';
import 'package:client/features/church/data/repositories/church_department_repository_impl.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/repositories/church_department_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final churchDepartmentsProvider = rawChurchDepartmentsProvider;
