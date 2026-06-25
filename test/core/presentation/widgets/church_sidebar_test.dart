import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/presentation/widgets/church_sidebar.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/data/datasources/active_unit_storage.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/providers/active_unit_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeActiveUnitStorage implements ActiveUnitStorage {
  String? selectedUnitId;
  final savedUnitIds = <String>[];

  @override
  Future<String?> readSelectedUnitId() async => selectedUnitId;

  @override
  Future<void> saveSelectedUnitId(String unitId) async {
    selectedUnitId = unitId;
    savedUnitIds.add(unitId);
  }

  @override
  Future<void> clearSelectedUnitId() async {
    selectedUnitId = null;
  }
}

const _unitOneMembership = MembershipEntity(
  id: 'membership-1',
  unitId: 'unit-1',
  affiliation: 'MEMBER',
  unitName: 'Unidade Central',
  unitProfileImageId: 'media-1',
);

const _unitTwoMembership = MembershipEntity(
  id: 'membership-2',
  unitId: 'unit-2',
  affiliation: 'CONGREGATED',
  unitName: 'Unidade Norte',
  unitProfileImageId: 'media-2',
);

const _permissions = SessionPermissions(
  isAuthenticated: true,
  affiliation: Affiliation.member,
  activeUnitId: 'unit-1',
  hasMembership: true,
  integrations: [],
  isUnitAdmin: false,
);

void main() {
  testWidgets('hides switch action when user has one unit', (tester) async {
    await _pumpSidebar(
      tester,
      memberships: const [_unitOneMembership],
      storage: _FakeActiveUnitStorage(),
    );

    await _openDrawer(tester);

    expect(find.text('Unidade Central'), findsOneWidget);
    expect(find.text('Trocar unidade'), findsNothing);
  });

  testWidgets('shows switch action and unit options for multiple units', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      memberships: const [_unitOneMembership, _unitTwoMembership],
      storage: _FakeActiveUnitStorage(),
    );

    await _openDrawer(tester);

    expect(find.text('Trocar unidade'), findsOneWidget);

    await tester.tap(find.text('Trocar unidade'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha uma unidade'), findsOneWidget);
    expect(find.text('Unidade Central'), findsWidgets);
    expect(find.text('Unidade Norte'), findsOneWidget);
  });

  testWidgets('selecting a unit persists the choice through active notifier', (
    tester,
  ) async {
    final storage = _FakeActiveUnitStorage();
    final router = await _pumpSidebar(
      tester,
      memberships: const [_unitOneMembership, _unitTwoMembership],
      storage: storage,
    );

    await _openDrawer(tester);
    await tester.tap(find.text('Trocar unidade'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unidade Norte'));
    await tester.pumpAndSettle();

    expect(storage.selectedUnitId, 'unit-2');
    expect(storage.savedUnitIds, ['unit-2']);
    expect(find.text('Escolha uma unidade'), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.homeChurch,
    );
  });
}

Future<GoRouter> _pumpSidebar(
  WidgetTester tester, {
  required List<MembershipEntity> memberships,
  required _FakeActiveUnitStorage storage,
}) async {
  final repository = _MockMembershipRepository();
  when(
    () => repository.getMyMemberships(),
  ).thenAnswer((_) async => Right(memberships));

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _SidebarHost()),
      GoRoute(
        path: AppRoutes.homeChurch,
        builder: (context, state) => const _SidebarHost(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        membershipRepositoryProvider.overrideWithValue(repository),
        activeUnitStorageProvider.overrideWithValue(storage),
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        sessionPermissionsProvider.overrideWith((ref) async => _permissions),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return router;
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open-sidebar')));
  await tester.pumpAndSettle();
}

CurrentChurchProfileEntity _profile() {
  return const CurrentChurchProfileEntity(
    membership: _unitOneMembership,
    unit: ChurchUnitEntity(
      id: 'unit-1',
      churchId: 'church-1',
      name: 'Unidade Central',
    ),
    church: ChurchEntity(
      id: 'church-1',
      name: 'Igreja Pontis',
      slug: 'igreja-pontis',
      email: 'contato@pontis.test',
    ),
  );
}

class _SidebarHost extends StatelessWidget {
  const _SidebarHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ChurchSidebar(),
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            key: const Key('open-sidebar'),
            onPressed: () => Scaffold.of(context).openDrawer(),
            child: const Text('Abrir sidebar'),
          ),
        ),
      ),
    );
  }
}
