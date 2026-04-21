import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

Future<List<DepartmentEntity>> _readDepartments(
  ProviderContainer container,
  String unitId,
) async {
  final completer = Completer<List<DepartmentEntity>>();
  final subscription = container.listen<AsyncValue<List<DepartmentEntity>>>(
    rawDepartmentsProvider(unitId),
    (previous, next) {
      if (next.hasValue && !completer.isCompleted) {
        completer.complete(next.requireValue);
      } else if (next.hasError && !completer.isCompleted) {
        completer.completeError(next.error!, next.stackTrace);
      }
    },
    fireImmediately: true,
  );

  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}

void main() {
  late _MockDepartmentRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockDepartmentRepository();
    container = ProviderContainer(
      overrides: [departmentRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('rawDepartmentsProvider returns departments from repository', () async {
    when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
      (_) async => const Right([
        DepartmentEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
      ]),
    );

    final result = await _readDepartments(container, 'unit-1');

    expect(result, hasLength(1));
    expect(result.first.name, 'Louvor');
  });

  test('rawDepartmentsProvider surfaces repository failures', () async {
    when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao buscar departamentos')),
    );

    expect(
      () => _readDepartments(container, 'unit-1'),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('filteredDepartmentsProvider returns ordered list for empty query', () async {
    when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
      (_) async => const Right([
        DepartmentEntity(
          id: 'dep-2',
          name: 'Secretaria',
          type: 'ADMINISTRATIVE',
        ),
        DepartmentEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
      ]),
    );

    await _readDepartments(container, 'unit-1');

    final result = container.read(filteredDepartmentsProvider('unit-1'));

    expect(
      result.requireValue.map((item) => item.name),
      ['Louvor', 'Secretaria'],
    );
  });

  test('filteredDepartmentsProvider filters by normalized name query', () async {
    when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
      (_) async => const Right([
        DepartmentEntity(
          id: 'dep-1',
          name: 'Ministério de Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
        DepartmentEntity(
          id: 'dep-2',
          name: 'Secretaria',
          type: 'ADMINISTRATIVE',
        ),
      ]),
    );

    await _readDepartments(container, 'unit-1');
    container.read(departmentSearchQueryProvider.notifier).update('ministerio');

    final result = container.read(filteredDepartmentsProvider('unit-1'));

    expect(
      result.requireValue.map((item) => item.name),
      ['Ministério de Louvor'],
    );
  });

  test('filteredDepartmentsProvider returns empty list when there are no matches', () async {
    when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
      (_) async => const Right([
        DepartmentEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
      ]),
    );

    await _readDepartments(container, 'unit-1');
    container.read(departmentSearchQueryProvider.notifier).update('infantil');

    final result = container.read(filteredDepartmentsProvider('unit-1'));

    expect(result.requireValue, isEmpty);
  });
}
