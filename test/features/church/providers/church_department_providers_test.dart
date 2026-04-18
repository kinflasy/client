import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/repositories/church_department_repository.dart';
import 'package:client/features/church/providers/church_department_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchDepartmentRepository extends Mock
    implements ChurchDepartmentRepository {}

Future<List<ChurchDepartmentEntity>> _readDepartments(
  ProviderContainer container,
  String unitId,
) async {
  final completer = Completer<List<ChurchDepartmentEntity>>();
  final subscription = container
      .listen<AsyncValue<List<ChurchDepartmentEntity>>>(
        rawChurchDepartmentsProvider(unitId),
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
  late _MockChurchDepartmentRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockChurchDepartmentRepository();
    container = ProviderContainer(
      overrides: [
        churchDepartmentRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'rawChurchDepartmentsProvider returns departments from repository',
    () async {
      when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
        (_) async => const Right([
          ChurchDepartmentEntity(
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
    },
  );

  test('rawChurchDepartmentsProvider surfaces repository failures', () async {
    when(() => repository.getDepartmentsByUnitId('unit-1')).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao buscar departamentos')),
    );

    expect(
      () => _readDepartments(container, 'unit-1'),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
