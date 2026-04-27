import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/domain/entities/pending_membership_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

Future<List<PendingMembershipEntity>> _readPendingMemberships(
  ProviderContainer container,
) async {
  final completer = Completer<List<PendingMembershipEntity>>();
  final subscription = container
      .listen<AsyncValue<List<PendingMembershipEntity>>>(
        myPendingMembershipsProvider,
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
  late _MockMembershipRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockMembershipRepository();
    when(
      () => repository.getMyMemberships(),
    ).thenAnswer((_) async => const Right([]));
    when(() => repository.getMyPendingMemberships()).thenAnswer(
      (_) async => Right([
        const PendingMembershipEntity(
          id: 'pending-1',
          unitId: 'unit-1',
          personId: 'person-1',
          affiliation: 'CONGREGATED',
        ),
        const PendingMembershipEntity(
          id: 'pending-2',
          unitId: 'unit-2',
          personId: 'person-1',
          affiliation: 'MEMBER',
        ),
      ]),
    );

    container = ProviderContainer(
      overrides: [membershipRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('myPendingMembershipsProvider returns pending memberships', () async {
    final memberships = await _readPendingMemberships(container);

    expect(memberships, hasLength(2));
    expect(memberships.first.unitId, 'unit-1');
    expect(memberships.last.affiliation, 'MEMBER');
  });

  test('pendingMembershipForUnitProvider filters by current unit', () async {
    await _readPendingMemberships(container);

    final pending = container.read(pendingMembershipForUnitProvider('unit-2'));

    expect(pending, isNotNull);
    expect(pending!.id, 'pending-2');
    expect(pending.matchesAffiliation('member'), isTrue);
  });

  test('pendingMembershipForUnitProvider ignores other units', () async {
    await _readPendingMemberships(container);

    final pending = container.read(pendingMembershipForUnitProvider('unit-3'));

    expect(pending, isNull);
  });

  test('myPendingMembershipsProvider throws repository failure', () async {
    when(() => repository.getMyPendingMemberships()).thenAnswer(
      (_) async => const Left(NetworkFailure('Erro ao buscar solicitacoes')),
    );

    final completer = Completer<Object>();
    final subscription = container.listen<
      AsyncValue<List<PendingMembershipEntity>>
    >(
      myPendingMembershipsProvider,
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
