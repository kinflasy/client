import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

Future<List<PendingUnitMembershipEntity>> _readPendingUnitMemberships(
  ProviderContainer container,
  String unitId,
) async {
  final completer = Completer<List<PendingUnitMembershipEntity>>();
  final subscription = container
      .listen<AsyncValue<List<PendingUnitMembershipEntity>>>(
        pendingUnitMembershipsProvider(unitId),
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
  late _MockChurchUnitRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockChurchUnitRepository();
    when(() => repository.getPendingMembers('unit-1')).thenAnswer(
      (_) async => const Right([
        PendingUnitMembershipEntity(
          id: 'pending-1',
          personId: 'person-1',
          unitId: 'unit-1',
          affiliation: 'CONGREGATED',
          fullName: 'Maria Clara',
        ),
      ]),
    );
    when(
      () => repository.confirmPendingMember('unit-1', 'person-1'),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.updatePendingMember('unit-1', 'person-1', any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.rejectPendingMember('unit-1', 'person-1'),
    ).thenAnswer((_) async => const Right(null));

    container = ProviderContainer(
      overrides: [churchUnitRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'pendingUnitMembershipsProvider returns pending unit memberships',
    () async {
      final memberships = await _readPendingUnitMemberships(
        container,
        'unit-1',
      );

      expect(memberships, hasLength(1));
      expect(memberships.first.personId, 'person-1');
      expect(memberships.first.fullName, 'Maria Clara');
      verify(() => repository.getPendingMembers('unit-1')).called(1);
    },
  );

  test('confirm invalidates pending unit memberships after success', () async {
    var reads = 0;
    when(() => repository.getPendingMembers('unit-1')).thenAnswer((_) async {
      reads++;
      return const Right([
        PendingUnitMembershipEntity(
          id: 'pending-1',
          personId: 'person-1',
          unitId: 'unit-1',
          affiliation: 'CONGREGATED',
        ),
      ]);
    });

    final subscription = container.listen(
      pendingUnitMembershipsProvider('unit-1'),
      (_, _) {},
      fireImmediately: true,
    );

    await container.read(pendingUnitMembershipsProvider('unit-1').future);
    final result = await container
        .read(pendingUnitMembershipActionProvider.notifier)
        .confirm('unit-1', 'person-1');
    await container.read(pendingUnitMembershipsProvider('unit-1').future);

    subscription.close();

    expect(result.isRight(), isTrue);
    expect(
      container.read(pendingUnitMembershipActionProvider),
      const AsyncData<void>(null),
    );
    expect(reads, 2);
    verify(
      () => repository.confirmPendingMember('unit-1', 'person-1'),
    ).called(1);
  });

  test('reject invalidates pending unit memberships after success', () async {
    var reads = 0;
    when(() => repository.getPendingMembers('unit-1')).thenAnswer((_) async {
      reads++;
      return const Right([
        PendingUnitMembershipEntity(
          id: 'pending-1',
          personId: 'person-1',
          unitId: 'unit-1',
          affiliation: 'CONGREGATED',
        ),
      ]);
    });

    final subscription = container.listen(
      pendingUnitMembershipsProvider('unit-1'),
      (_, _) {},
      fireImmediately: true,
    );

    await container.read(pendingUnitMembershipsProvider('unit-1').future);
    final result = await container
        .read(pendingUnitMembershipActionProvider.notifier)
        .reject('unit-1', 'person-1');
    await container.read(pendingUnitMembershipsProvider('unit-1').future);

    subscription.close();

    expect(result.isRight(), isTrue);
    expect(
      container.read(pendingUnitMembershipActionProvider),
      const AsyncData<void>(null),
    );
    expect(reads, 2);
    verify(
      () => repository.rejectPendingMember('unit-1', 'person-1'),
    ).called(1);
  });

  test(
    'approveWithAffiliation updates and confirms before invalidating the list',
    () async {
      var reads = 0;
      when(() => repository.getPendingMembers('unit-1')).thenAnswer((_) async {
        reads++;
        return const Right([
          PendingUnitMembershipEntity(
            id: 'pending-1',
            personId: 'person-1',
            unitId: 'unit-1',
            affiliation: 'CONGREGATED',
          ),
        ]);
      });

      final calls = <String>[];
      when(
        () => repository.updatePendingMember('unit-1', 'person-1', 'MEMBER'),
      ).thenAnswer((_) async {
        calls.add('update');
        return const Right(null);
      });
      when(
        () => repository.confirmPendingMember('unit-1', 'person-1'),
      ).thenAnswer((_) async {
        calls.add('confirm');
        return const Right(null);
      });

      final subscription = container.listen(
        pendingUnitMembershipsProvider('unit-1'),
        (_, _) {},
        fireImmediately: true,
      );

      await container.read(pendingUnitMembershipsProvider('unit-1').future);
      final result = await container
          .read(pendingUnitMembershipActionProvider.notifier)
          .approveWithAffiliation('unit-1', 'person-1', 'MEMBER');
      await container.read(pendingUnitMembershipsProvider('unit-1').future);

      subscription.close();

      expect(result.isRight(), isTrue);
      expect(calls, ['update', 'confirm']);
      expect(reads, 2);
      expect(
        container.read(pendingUnitMembershipActionProvider),
        const AsyncData<void>(null),
      );
    },
  );

  test(
    'approveWithAffiliation does not confirm or invalidate when update fails',
    () async {
      var reads = 0;
      when(() => repository.getPendingMembers('unit-1')).thenAnswer((_) async {
        reads++;
        return const Right([
          PendingUnitMembershipEntity(
            id: 'pending-1',
            personId: 'person-1',
            unitId: 'unit-1',
            affiliation: 'CONGREGATED',
          ),
        ]);
      });
      when(
        () => repository.updatePendingMember('unit-1', 'person-1', 'MEMBER'),
      ).thenAnswer(
        (_) async =>
            const Left(NetworkFailure('Falha ao atualizar a pendência.')),
      );

      final subscription = container.listen(
        pendingUnitMembershipsProvider('unit-1'),
        (_, _) {},
        fireImmediately: true,
      );

      await container.read(pendingUnitMembershipsProvider('unit-1').future);
      final result = await container
          .read(pendingUnitMembershipActionProvider.notifier)
          .approveWithAffiliation('unit-1', 'person-1', 'MEMBER');

      subscription.close();

      expect(result.isLeft(), isTrue);
      expect(reads, 1);
      verifyNever(() => repository.confirmPendingMember('unit-1', 'person-1'));
      expect(
        container.read(pendingUnitMembershipActionProvider).hasError,
        isTrue,
      );
    },
  );

  test(
    'approveWithAffiliation does not invalidate when confirm fails after update succeeds',
    () async {
      var reads = 0;
      when(() => repository.getPendingMembers('unit-1')).thenAnswer((_) async {
        reads++;
        return const Right([
          PendingUnitMembershipEntity(
            id: 'pending-1',
            personId: 'person-1',
            unitId: 'unit-1',
            affiliation: 'CONGREGATED',
          ),
        ]);
      });
      when(
        () => repository.updatePendingMember('unit-1', 'person-1', 'MEMBER'),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => repository.confirmPendingMember('unit-1', 'person-1'),
      ).thenAnswer(
        (_) async => const Left(
          NetworkFailure('Falha ao concluir a aprovação da solicitação.'),
        ),
      );

      final subscription = container.listen(
        pendingUnitMembershipsProvider('unit-1'),
        (_, _) {},
        fireImmediately: true,
      );

      await container.read(pendingUnitMembershipsProvider('unit-1').future);
      final result = await container
          .read(pendingUnitMembershipActionProvider.notifier)
          .approveWithAffiliation('unit-1', 'person-1', 'MEMBER');

      subscription.close();

      expect(result.isLeft(), isTrue);
      expect(reads, 1);
      verify(
        () => repository.updatePendingMember('unit-1', 'person-1', 'MEMBER'),
      ).called(1);
      verify(
        () => repository.confirmPendingMember('unit-1', 'person-1'),
      ).called(1);
      expect(
        container.read(pendingUnitMembershipActionProvider).hasError,
        isTrue,
      );
    },
  );

  test('pendingUnitMembershipsProvider throws repository failure', () async {
    when(() => repository.getPendingMembers('unit-1')).thenAnswer(
      (_) async =>
          const Left(NetworkFailure('Erro ao buscar solicitacoes da unidade')),
    );

    final completer = Completer<Object>();
    final subscription = container
        .listen<AsyncValue<List<PendingUnitMembershipEntity>>>(
          pendingUnitMembershipsProvider('unit-1'),
          (previous, next) {
            if (next.hasError && !completer.isCompleted) {
              completer.complete(next.error!);
            }
          },
          fireImmediately: true,
        );

    try {
      await expectLater(completer.future, completion(isA<NetworkFailure>()));
    } finally {
      subscription.close();
    }
  });
}
