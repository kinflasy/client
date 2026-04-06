import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/repositories/church_repository.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchRepository extends Mock implements ChurchRepository {}

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

void main() {
  late _MockChurchRepository churchRepository;
  late _MockChurchUnitRepository unitRepository;

  setUp(() {
    churchRepository = _MockChurchRepository();
    unitRepository = _MockChurchUnitRepository();
  });

  test('returns not found when there is no active membership', () async {
    await expectLater(
      resolveCurrentChurchProfile(
        activeMembership: null,
        unitRepository: unitRepository,
        churchRepository: churchRepository,
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('resolves membership, unit and church successfully', () async {
    when(() => unitRepository.getUnitById('unit-1')).thenAnswer(
      (invocation) async => const Right(
        ChurchUnitEntity(id: 'unit-1', churchId: 'church-1', name: 'Sede'),
      ),
    );
    when(() => churchRepository.getChurchById('church-1')).thenAnswer(
      (invocation) async => const Right(
        ChurchEntity(
          id: 'church-1',
          name: 'Igreja Central',
          slug: 'igreja-central',
          email: 'contato@igreja.dev',
        ),
      ),
    );

    final profile = await resolveCurrentChurchProfile(
      activeMembership: const MembershipEntity(
        id: 'membership-1',
        unitId: 'unit-1',
        affiliation: 'MEMBER',
      ),
      unitRepository: unitRepository,
      churchRepository: churchRepository,
    );

    expect(profile.membership.id, 'membership-1');
    expect(profile.unit.id, 'unit-1');
    expect(profile.church.id, 'church-1');
  });

  test('propagates unit lookup failures', () async {
    when(() => unitRepository.getUnitById('unit-1')).thenAnswer(
      (invocation) async =>
          const Left(NetworkFailure('Erro ao buscar a unidade.')),
    );

    await expectLater(
      resolveCurrentChurchProfile(
        activeMembership: const MembershipEntity(
          id: 'membership-1',
          unitId: 'unit-1',
          affiliation: 'MEMBER',
        ),
        unitRepository: unitRepository,
        churchRepository: churchRepository,
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('propagates church lookup failures', () async {
    when(() => unitRepository.getUnitById('unit-1')).thenAnswer(
      (invocation) async =>
          const Right(ChurchUnitEntity(id: 'unit-1', churchId: 'church-1')),
    );
    when(() => churchRepository.getChurchById('church-1')).thenAnswer(
      (invocation) async =>
          const Left(NotFoundFailure('Igreja não encontrada.')),
    );

    await expectLater(
      resolveCurrentChurchProfile(
        activeMembership: const MembershipEntity(
          id: 'membership-1',
          unitId: 'unit-1',
          affiliation: 'MEMBER',
        ),
        unitRepository: unitRepository,
        churchRepository: churchRepository,
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('resolves public unit profile successfully', () async {
    when(() => unitRepository.getUnitById('unit-1')).thenAnswer(
      (_) async => const Right(
        ChurchUnitEntity(
          id: 'unit-1',
          churchId: 'church-1',
          name: 'Sede',
          type: 'MAIN',
        ),
      ),
    );
    when(() => churchRepository.getChurchById('church-1')).thenAnswer(
      (_) async => const Right(
        ChurchEntity(
          id: 'church-1',
          name: 'Igreja Central',
          slug: 'igreja-central',
          email: 'contato@igreja.dev',
        ),
      ),
    );
    when(() => unitRepository.getUnitsByChurchId('church-1')).thenAnswer(
      (_) async => const Right([
        ChurchUnitEntity(
          id: 'unit-1',
          churchId: 'church-1',
          name: 'Sede',
          type: 'MAIN',
        ),
        ChurchUnitEntity(
          id: 'unit-2',
          churchId: 'church-1',
          name: 'Filial',
          type: 'BRANCH',
        ),
      ]),
    );

    final profile = await resolvePublicChurchUnitProfile(
      unitId: 'unit-1',
      unitRepository: unitRepository,
      churchRepository: churchRepository,
    );

    expect(profile.unit.id, 'unit-1');
    expect(profile.church.id, 'church-1');
    expect(profile.relatedUnits, hasLength(2));
  });

  test('resolves headquarter unit successfully', () async {
    when(() => unitRepository.getUnitsByChurchId('church-1')).thenAnswer(
      (_) async => const Right([
        ChurchUnitEntity(
          id: 'unit-2',
          churchId: 'church-1',
          name: 'Filial',
          type: 'BRANCH',
        ),
        ChurchUnitEntity(
          id: 'unit-1',
          churchId: 'church-1',
          name: 'Sede',
          type: 'MAIN',
        ),
      ]),
    );

    final unit = await resolveHeadquarterUnitByChurch(
      churchId: 'church-1',
      unitRepository: unitRepository,
    );

    expect(unit.id, 'unit-1');
    expect(unit.type, 'MAIN');
  });

  test('fails when no headquarter marker is present', () async {
    when(() => unitRepository.getUnitsByChurchId('church-1')).thenAnswer(
      (_) async => const Right([
        ChurchUnitEntity(
          id: 'unit-2',
          churchId: 'church-1',
          name: 'Filial',
          type: 'BRANCH',
        ),
      ]),
    );

    await expectLater(
      resolveHeadquarterUnitByChurch(
        churchId: 'church-1',
        unitRepository: unitRepository,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('propagates headquarter lookup errors', () async {
    when(() => unitRepository.getUnitsByChurchId('church-1')).thenAnswer(
      (_) async => const Left(NetworkFailure('Erro ao buscar unidades.')),
    );

    await expectLater(
      resolveHeadquarterUnitByChurch(
        churchId: 'church-1',
        unitRepository: unitRepository,
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
