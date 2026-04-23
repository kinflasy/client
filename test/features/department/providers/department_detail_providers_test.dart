import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

Future<T> _readFutureProvider<T>(ProviderContainer container, dynamic provider) async {
  final completer = Completer<T>();
  final subscription = container.listen<AsyncValue<T>>(
    provider,
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

  group('departmentDetailProvider', () {
    test('returns department detail from repository', () async {
      when(() => repository.getDepartmentById('dep-1')).thenAnswer(
        (_) async => const Right(
          DepartmentDetailEntity(
            id: 'dep-1',
            name: 'Louvor',
            slug: 'louvor',
            type: 'MINISTRY',
          ),
        ),
      );

      final result = await _readFutureProvider(
        container,
        departmentDetailProvider('dep-1'),
      );

      expect(result.name, 'Louvor');
      expect(result.slug, 'louvor');
    });

    test('surfaces repository failure', () async {
      when(() => repository.getDepartmentById('dep-1')).thenAnswer(
        (_) async => const Left(NetworkFailure('Falha ao carregar departamento')),
      );

      await expectLater(
        _readFutureProvider(
          container,
          departmentDetailProvider('dep-1'),
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('departmentParticipantsProvider', () {
    test('returns participants from repository', () async {
      when(() => repository.getParticipants('dep-1')).thenAnswer(
        (_) async => const Right([
          DepartmentParticipantEntity(
            personId: 'person-1',
            fullName: 'Maria Silva',
            affiliation: 'MEMBER',
            gender: 'FEMALE',
          ),
        ]),
      );

      final result = await _readFutureProvider(
        container,
        departmentParticipantsProvider('dep-1'),
      );

      expect(result, hasLength(1));
      expect(result.first.fullName, 'Maria Silva');
    });

    test('returns empty list when repository has no participants', () async {
      when(() => repository.getParticipants('dep-1')).thenAnswer(
        (_) async => const Right(<DepartmentParticipantEntity>[]),
      );

      final result = await _readFutureProvider(
        container,
        departmentParticipantsProvider('dep-1'),
      );

      expect(result, isEmpty);
    });

    test('surfaces repository failure', () async {
      when(() => repository.getParticipants('dep-1')).thenAnswer(
        (_) async => const Left(NetworkFailure('Falha ao carregar participantes')),
      );

      await expectLater(
        _readFutureProvider(
          container,
          departmentParticipantsProvider('dep-1'),
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
