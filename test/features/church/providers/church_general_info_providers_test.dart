import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/address/address_request_model.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/models/church_request_model.dart';
import 'package:client/features/church/domain/entities/church_link_entity.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_general_info_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

class _FakeUnitRequestModel extends Fake implements UnitRequestModel {}

void main() {
  late _MockChurchUnitRepository repository;

  const currentUnit = ChurchUnitEntity(
    id: 'unit-1',
    churchId: 'church-1',
    type: 'BRANCH',
  );

  setUpAll(() {
    registerFallbackValue(_FakeUnitRequestModel());
  });

  setUp(() {
    repository = _MockChurchUnitRepository();
  });

  test('buildUpdateUnitRequest preserves current unit type', () {
    const request = AddressRequestModel(city: 'Fortaleza', state: 'CE');

    final result = buildUpdateUnitRequest(
      currentUnit: currentUnit,
      name: 'Filial',
      slug: 'filial',
      phone: '(85) 99999-0000',
      email: 'filial@igreja.dev',
      address: request,
    );

    expect(result.name, 'Filial');
    expect(result.slug, 'filial');
    expect(result.type, 'BRANCH');
    expect(result.address, request);
  });

  test('buildUpdateUnitRequest falls back to MAIN when type is absent', () {
    final result = buildUpdateUnitRequest(
      currentUnit: const ChurchUnitEntity(id: 'unit-1', churchId: 'church-1'),
      name: 'Sede',
      slug: 'sede',
      phone: '(85) 99999-0000',
      email: 'sede@igreja.dev',
      address: const AddressRequestModel(city: 'Fortaleza'),
    );

    expect(result.type, 'MAIN');
  });

  test('unitLinksProvider returns links for a unit', () async {
    when(() => repository.getUnitLinks('unit-1')).thenAnswer(
      (_) async => const Right([
        ChurchLinkEntity(
          id: 'link-1',
          label: 'Website',
          url: 'https://igreja.dev',
        ),
      ]),
    );

    final container = ProviderContainer(
      overrides: [churchUnitRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final links = await container.read(unitLinksProvider('unit-1').future);

    expect(links, hasLength(1));
    expect(links.first.label, 'Website');
    expect(links.first.url, 'https://igreja.dev');
  });

  test('unitLinksProvider throws repository failure', () async {
    when(() => repository.getUnitLinks('unit-1')).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao carregar links.')),
    );

    final container = ProviderContainer(
      overrides: [churchUnitRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      unitLinksProvider('unit-1'),
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(unitLinksProvider('unit-1'));
    expect(state.hasError, isTrue);
    expect(
      state.error,
      isA<NetworkFailure>().having(
        (failure) => failure.message,
        'message',
        'Falha ao carregar links.',
      ),
    );
  });

  test('updates unit and invalidates related providers on success', () async {
    var currentProfileLoads = 0;
    var publicProfileLoads = 0;
    var headquarterLoads = 0;

    when(
      () => repository.updateUnit('unit-1', any(that: isA<UnitRequestModel>())),
    ).thenAnswer((_) async => const Right(currentUnit));

    final container = ProviderContainer(
      overrides: [
        churchUnitRepositoryProvider.overrideWithValue(repository),
        currentChurchProfileProvider.overrideWith((ref) async {
          currentProfileLoads++;
          return _currentProfile(currentUnit);
        }),
        publicChurchUnitProfileProvider.overrideWith((ref, unitId) async {
          publicProfileLoads++;
          return _publicProfile(currentUnit);
        }),
        headquarterUnitByChurchProvider.overrideWith((ref, churchId) async {
          headquarterLoads++;
          return currentUnit;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(currentChurchProfileProvider.future);
    await container.read(publicChurchUnitProfileProvider('unit-1').future);
    await container.read(headquarterUnitByChurchProvider('church-1').future);

    final result = await container
        .read(churchGeneralInfoActionsProvider)
        .updateUnitGeneralInfo(
          currentUnit: currentUnit,
          name: 'Filial',
          slug: 'filial',
          phone: '(85) 99999-0000',
          email: 'filial@igreja.dev',
          address: const AddressRequestModel(city: 'Fortaleza', state: 'CE'),
        );

    expect(result.isRight(), isTrue);
    expect(
      container.read(editChurchUnitGeneralInfoSubmitProvider),
      const AsyncValue<void>.data(null),
    );
    final captured =
        verify(
              () => repository.updateUnit('unit-1', captureAny()),
            ).captured.single
            as UnitRequestModel;
    expect(captured.type, 'BRANCH');

    await container.read(currentChurchProfileProvider.future);
    await container.read(publicChurchUnitProfileProvider('unit-1').future);
    await container.read(headquarterUnitByChurchProvider('church-1').future);

    expect(currentProfileLoads, 2);
    expect(publicProfileLoads, 2);
    expect(headquarterLoads, 2);
  });

  test('stores submit error when update fails', () async {
    when(
      () => repository.updateUnit('unit-1', any(that: isA<UnitRequestModel>())),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha ao salvar.')));

    final container = ProviderContainer(
      overrides: [churchUnitRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(churchGeneralInfoActionsProvider)
        .updateUnitGeneralInfo(
          currentUnit: currentUnit,
          name: 'Filial',
          slug: 'filial',
          phone: '(85) 99999-0000',
          email: 'filial@igreja.dev',
          address: const AddressRequestModel(city: 'Fortaleza', state: 'CE'),
        );

    expect(result.isLeft(), isTrue);
    expect(
      container.read(editChurchUnitGeneralInfoSubmitProvider),
      isA<AsyncError<void>>(),
    );
  });

  test(
    'createEditChurchUnitInfoFormStateFromUnit initializes with unit data',
    () {
      final unit = ChurchUnitEntity(
        id: 'unit-1',
        churchId: 'church-1',
        name: 'Filial Centro',
        slug: 'filial-centro',
        phone: '(85) 99999-0000',
        email: 'centro@igreja.dev',
        type: 'BRANCH',
      );

      final state = createEditChurchUnitInfoFormStateFromUnit(unit);

      expect(state.name, 'Filial Centro');
      expect(state.slug, 'filial-centro');
      expect(state.phone, '(85) 99999-0000');
      expect(state.email, 'centro@igreja.dev');
      expect(state.isInitialized, isTrue);
    },
  );

  test('createEditChurchUnitInfoFormStateFromUnit handles null fields', () {
    final unit = const ChurchUnitEntity(id: 'unit-1', churchId: 'church-1');

    final state = createEditChurchUnitInfoFormStateFromUnit(unit);

    expect(state.name, '');
    expect(state.slug, '');
    expect(state.phone, '');
    expect(state.email, '');
    expect(state.isInitialized, isTrue);
  });

  test(
    'createEditChurchUnitInfoFormStateFromUnit falls back to church identity',
    () {
      const unit = ChurchUnitEntity(
        id: 'unit-1',
        churchId: 'church-1',
        name: ' ',
        slug: null,
        phone: null,
        email: '',
      );

      final state = createEditChurchUnitInfoFormStateFromUnit(
        unit,
        fallbackChurch: _church,
      );

      expect(state.name, 'Igreja Central');
      expect(state.slug, 'igreja-central');
      expect(state.phone, '');
      expect(state.email, 'contato@igreja.dev');
    },
  );

  test('buildEditChurchUnitInfoRequest builds request with form state', () {
    const formState = EditChurchUnitInfoFormState(
      name: 'Filial',
      slug: 'filial',
      phone: '(85) 99999-0000',
      email: 'filial@igreja.dev',
      address: AddressFormState(city: 'Fortaleza', state: 'CE'),
      isInitialized: true,
    );

    final result = buildEditChurchUnitInfoRequest(formState, currentUnit);

    expect(result.name, 'Filial');
    expect(result.slug, 'filial');
    expect(result.phone, '(85) 99999-0000');
    expect(result.email, 'filial@igreja.dev');
    expect(result.type, 'BRANCH');
    expect(result.address.city, 'Fortaleza');
  });

  test('buildEditChurchUnitInfoRequest preserves unit type', () {
    const formState = EditChurchUnitInfoFormState(
      name: 'Filial',
      slug: 'filial',
      phone: '(85) 99999-0000',
      email: 'filial@igreja.dev',
    );

    final result = buildEditChurchUnitInfoRequest(formState, currentUnit);

    expect(result.type, 'BRANCH');
  });

  test(
    'buildEditChurchUnitInfoRequest falls back to MAIN when type is absent',
    () {
      const formState = EditChurchUnitInfoFormState(
        name: 'Sede',
        slug: 'sede',
        phone: '(85) 99999-0000',
        email: 'sede@igreja.dev',
      );

      final unitWithoutType = const ChurchUnitEntity(
        id: 'unit-1',
        churchId: 'church-1',
      );

      final result = buildEditChurchUnitInfoRequest(formState, unitWithoutType);

      expect(result.type, 'MAIN');
    },
  );
}

CurrentChurchProfileEntity _currentProfile(ChurchUnitEntity unit) {
  return CurrentChurchProfileEntity(
    membership: const MembershipEntity(
      id: 'membership-1',
      unitId: 'unit-1',
      affiliation: 'MEMBER',
    ),
    unit: unit,
    church: _church,
  );
}

PublicChurchUnitProfileEntity _publicProfile(ChurchUnitEntity unit) {
  return PublicChurchUnitProfileEntity(
    unit: unit,
    church: _church,
    relatedUnits: const [currentUnit],
  );
}

const _church = ChurchEntity(
  id: 'church-1',
  name: 'Igreja Central',
  slug: 'igreja-central',
  email: 'contato@igreja.dev',
);

const currentUnit = ChurchUnitEntity(
  id: 'unit-1',
  churchId: 'church-1',
  type: 'BRANCH',
);
