import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/pending_membership_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockChurchUnitRepository churchUnitRepository;
  late _MockMembershipRepository membershipRepository;
  late ProviderContainer container;

  setUp(() {
    churchUnitRepository = _MockChurchUnitRepository();
    membershipRepository = _MockMembershipRepository();

    when(
      () => churchUnitRepository.joinUnit('unit-1', 'CONGREGATED'),
    ).thenAnswer((_) async => const Right(null));
  });

  tearDown(() {
    container.dispose();
  });

  test('join invalidates pending memberships and public profile after success', () async {
    var pendingReads = 0;
    var profileReads = 0;

    when(() => membershipRepository.getMyPendingMemberships()).thenAnswer((
      _,
    ) async {
      pendingReads++;
      return const Right([
        PendingMembershipEntity(
          id: 'pending-1',
          unitId: 'unit-1',
          affiliation: 'CONGREGATED',
        ),
      ]);
    });

    container = ProviderContainer(
      overrides: [
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        membershipRepositoryProvider.overrideWithValue(membershipRepository),
        publicChurchUnitProfileProvider.overrideWith((ref, unitId) async {
          profileReads++;
          return const PublicChurchUnitProfileEntity(
            unit: ChurchUnitEntity(
              id: 'unit-1',
              churchId: 'church-1',
              name: 'Sede Central',
              type: 'MAIN',
            ),
            church: ChurchEntity(
              id: 'church-1',
              name: 'Igreja Central',
              slug: 'igreja-central',
              email: 'contato@igreja.dev',
            ),
            relatedUnits: [],
          );
        }),
      ],
    );

    final pendingSubscription = container.listen(
      myPendingMembershipsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final profileSubscription = container.listen(
      publicChurchUnitProfileProvider('unit-1'),
      (_, _) {},
      fireImmediately: true,
    );

    await container.read(myPendingMembershipsProvider.future);
    await container.read(publicChurchUnitProfileProvider('unit-1').future);

    final result = await container
        .read(joinChurchUnitProvider.notifier)
        .join('unit-1', 'CONGREGATED');

    await container.read(myPendingMembershipsProvider.future);
    await container.read(publicChurchUnitProfileProvider('unit-1').future);

    pendingSubscription.close();
    profileSubscription.close();

    expect(result.isRight(), isTrue);
    expect(container.read(joinChurchUnitProvider), const AsyncData<void>(null));
    expect(pendingReads, 2);
    expect(profileReads, 2);
    verify(
      () => churchUnitRepository.joinUnit('unit-1', 'CONGREGATED'),
    ).called(1);
    verify(() => membershipRepository.getMyPendingMemberships()).called(2);
  });
}
