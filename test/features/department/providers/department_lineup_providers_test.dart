import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/data/models/role_request_model.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _FakeRoleRequestModel extends Fake implements RoleRequestModel {}

class _FakeLineupRequestModel extends Fake implements LineupRequestModel {}

class _FakeLineupItemRequestModel extends Fake
    implements LineupItemRequestModel {}

class _FakeLineupItemUpdateRequestModel extends Fake
    implements LineupItemUpdateRequestModel {}

Future<T> _readFutureProvider<T>(
  ProviderContainer container,
  dynamic provider,
) async {
  final completer = Completer<T>();
  final subscription = container.listen<AsyncValue<T>>(provider, (
    previous,
    next,
  ) {
    if (next.hasValue && !completer.isCompleted) {
      completer.complete(next.requireValue);
    } else if (next.hasError && !completer.isCompleted) {
      completer.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);

  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}

void main() {
  late _MockDepartmentRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(_FakeRoleRequestModel());
    registerFallbackValue(_FakeLineupRequestModel());
    registerFallbackValue(_FakeLineupItemRequestModel());
    registerFallbackValue(_FakeLineupItemUpdateRequestModel());
  });

  setUp(() {
    repository = _MockDepartmentRepository();
    container = ProviderContainer(
      overrides: [departmentRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('rolesProvider', () {
    test('returns roles sorted by name', () async {
      when(() => repository.getRoles()).thenAnswer(
        (_) async => const Right([
          RoleEntity(id: 'role-2', name: 'Zeladoria', slug: 'zeladoria'),
          RoleEntity(id: 'role-1', name: 'Apoio', slug: 'apoio'),
        ]),
      );

      final result = await _readFutureProvider(container, rolesProvider);

      expect(result.map((role) => role.name), ['Apoio', 'Zeladoria']);
    });

    test('filters locally ignoring accents and case', () async {
      when(() => repository.getRoles()).thenAnswer(
        (_) async => const Right([
          RoleEntity(id: 'role-1', name: 'Violão', slug: 'violao'),
          RoleEntity(id: 'role-2', name: 'Vocal', slug: 'vocal'),
        ]),
      );

      final result = await _readFutureProvider(
        container,
        filteredRolesProvider('VIOLAO'),
      );

      expect(result, const [
        RoleEntity(id: 'role-1', name: 'Violão', slug: 'violao'),
      ]);
    });
  });

  group('departmentLineupsProvider', () {
    test('returns lineups sorted by name', () async {
      when(() => repository.getDepartmentLineups('dep-1')).thenAnswer(
        (_) async => const Right([
          LineupEntity(id: 'lineup-2', name: 'Zeladoria'),
          LineupEntity(id: 'lineup-1', name: 'Culto'),
        ]),
      );

      final result = await _readFutureProvider(
        container,
        departmentLineupsProvider('dep-1'),
      );

      expect(result.map((lineup) => lineup.name), ['Culto', 'Zeladoria']);
    });
  });

  group('roleActionsProvider', () {
    test('invalidates roles after create success', () async {
      when(
        () => repository.getRoles(),
      ).thenAnswer((_) async => const Right(<RoleEntity>[]));
      when(() => repository.createRole(any())).thenAnswer(
        (_) async =>
            const Right(RoleEntity(id: 'role-1', name: 'Apoio', slug: 'apoio')),
      );

      final subscription = container.listen(
        rolesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(rolesProvider.future);
      await container
          .read(roleActionsProvider.notifier)
          .create(const RoleRequestModel(name: 'Apoio'));
      await container.read(rolesProvider.future);

      verify(() => repository.getRoles()).called(2);
    });

    test('does not invalidate roles after create failure', () async {
      when(
        () => repository.getRoles(),
      ).thenAnswer((_) async => const Right(<RoleEntity>[]));
      when(() => repository.createRole(any())).thenAnswer(
        (_) async => const Left(ValidationFailure('Papel inválido.')),
      );

      await container.read(rolesProvider.future);
      await container
          .read(roleActionsProvider.notifier)
          .create(const RoleRequestModel(name: 'Apoio'));
      await container.read(rolesProvider.future);

      verify(() => repository.getRoles()).called(1);
    });
  });

  group('lineupActionsProvider', () {
    test(
      'invalidates department list and lineup details after update success',
      () async {
        _stubLineupReads(repository);
        when(() => repository.updateLineup('lineup-1', any())).thenAnswer(
          (_) async => const Right(
            LineupEntity(id: 'lineup-1', name: 'Culto atualizado'),
          ),
        );

        final subscriptions = [
          container.listen(
            departmentLineupsProvider('dep-1'),
            (_, _) {},
            fireImmediately: true,
          ),
          container.listen(
            lineupWithItemsProvider('lineup-1'),
            (_, _) {},
            fireImmediately: true,
          ),
          container.listen(
            lineupItemsProvider('lineup-1'),
            (_, _) {},
            fireImmediately: true,
          ),
        ];
        for (final subscription in subscriptions) {
          addTearDown(subscription.close);
        }

        await container.read(departmentLineupsProvider('dep-1').future);
        await container.read(lineupWithItemsProvider('lineup-1').future);
        await container.read(lineupItemsProvider('lineup-1').future);
        await container
            .read(lineupActionsProvider.notifier)
            .update(
              departmentId: 'dep-1',
              lineupId: 'lineup-1',
              request: const LineupRequestModel(name: 'Culto atualizado'),
            );
        await container.read(departmentLineupsProvider('dep-1').future);
        await container.read(lineupWithItemsProvider('lineup-1').future);
        await container.read(lineupItemsProvider('lineup-1').future);

        verify(() => repository.getDepartmentLineups('dep-1')).called(2);
        verify(() => repository.getLineupWithItems('lineup-1')).called(2);
        verify(() => repository.getLineupItems('lineup-1')).called(2);
      },
    );

    test('does not invalidate department list after delete failure', () async {
      when(
        () => repository.getDepartmentLineups('dep-1'),
      ).thenAnswer((_) async => const Right(<LineupEntity>[]));
      when(
        () => repository.deleteLineup('lineup-1'),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

      await container.read(departmentLineupsProvider('dep-1').future);
      await container
          .read(lineupActionsProvider.notifier)
          .delete(departmentId: 'dep-1', lineupId: 'lineup-1');
      await container.read(departmentLineupsProvider('dep-1').future);

      verify(() => repository.getDepartmentLineups('dep-1')).called(1);
    });
  });

  group('lineupItemActionsProvider', () {
    test(
      'invalidates item, detail and department list after create success',
      () async {
        _stubLineupReads(repository);
        when(() => repository.createLineupItem('lineup-1', any())).thenAnswer(
          (_) async => const Right(
            LineupItemEntity(
              id: 'item-1',
              lineupId: 'lineup-1',
              roleId: 'role-1',
              description: 'Vocal principal',
            ),
          ),
        );

        final subscriptions = [
          container.listen(
            departmentLineupsProvider('dep-1'),
            (_, _) {},
            fireImmediately: true,
          ),
          container.listen(
            lineupWithItemsProvider('lineup-1'),
            (_, _) {},
            fireImmediately: true,
          ),
          container.listen(
            lineupItemsProvider('lineup-1'),
            (_, _) {},
            fireImmediately: true,
          ),
        ];
        for (final subscription in subscriptions) {
          addTearDown(subscription.close);
        }

        await container.read(departmentLineupsProvider('dep-1').future);
        await container.read(lineupWithItemsProvider('lineup-1').future);
        await container.read(lineupItemsProvider('lineup-1').future);
        await container
            .read(lineupItemActionsProvider.notifier)
            .create(
              lineupId: 'lineup-1',
              departmentId: 'dep-1',
              request: const LineupItemRequestModel(
                roleId: 'role-1',
                description: 'Vocal principal',
              ),
            );
        await container.read(departmentLineupsProvider('dep-1').future);
        await container.read(lineupWithItemsProvider('lineup-1').future);
        await container.read(lineupItemsProvider('lineup-1').future);

        verify(() => repository.getDepartmentLineups('dep-1')).called(2);
        verify(() => repository.getLineupWithItems('lineup-1')).called(2);
        verify(() => repository.getLineupItems('lineup-1')).called(2);
      },
    );

    test('does not invalidate item list after update failure', () async {
      when(
        () => repository.getLineupItems('lineup-1'),
      ).thenAnswer((_) async => const Right(<LineupItemEntity>[]));
      when(
        () => repository.updateLineupItem('item-1', any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

      await container.read(lineupItemsProvider('lineup-1').future);
      await container
          .read(lineupItemActionsProvider.notifier)
          .update(
            lineupId: 'lineup-1',
            itemId: 'item-1',
            request: const LineupItemUpdateRequestModel(
              description: 'Vocal de apoio',
            ),
          );
      await container.read(lineupItemsProvider('lineup-1').future);

      verify(() => repository.getLineupItems('lineup-1')).called(1);
    });
  });
}

void _stubLineupReads(_MockDepartmentRepository repository) {
  when(
    () => repository.getDepartmentLineups('dep-1'),
  ).thenAnswer((_) async => const Right(<LineupEntity>[]));
  when(() => repository.getLineupWithItems('lineup-1')).thenAnswer(
    (_) async => const Right(LineupEntity(id: 'lineup-1', name: 'Culto')),
  );
  when(
    () => repository.getLineupItems('lineup-1'),
  ).thenAnswer((_) async => const Right(<LineupItemEntity>[]));
}
