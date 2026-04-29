import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/presentation/screens/church_info_profile_screen.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/pending_membership_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

void main() {
  PublicChurchUnitProfileEntity buildMainProfile() {
    return const PublicChurchUnitProfileEntity(
      unit: ChurchUnitEntity(
        id: 'unit-1',
        churchId: 'church-1',
        name: 'Sede Central',
        slug: 'sede-central',
        address: 'Rua A, 10',
        phone: '(11) 99999-0000',
        email: 'sede@igreja.dev',
        type: 'MAIN',
      ),
      church: ChurchEntity(
        id: 'church-1',
        name: 'Igreja Central',
        slug: 'igreja-central',
        email: 'contato@igreja.dev',
      ),
      relatedUnits: [
        ChurchUnitEntity(
          id: 'unit-1',
          churchId: 'church-1',
          name: 'Sede Central',
          slug: 'sede-central',
          type: 'MAIN',
        ),
        ChurchUnitEntity(
          id: 'unit-2',
          churchId: 'church-1',
          name: 'Filial Leste',
          slug: 'filial-leste',
          type: 'BRANCH',
        ),
      ],
    );
  }

  PublicChurchUnitProfileEntity buildBranchProfile() {
    return const PublicChurchUnitProfileEntity(
      unit: ChurchUnitEntity(
        id: 'unit-2',
        churchId: 'church-1',
        name: 'Filial Leste',
        slug: 'filial-leste',
        email: 'filial@igreja.dev',
        type: 'BRANCH',
      ),
      church: ChurchEntity(
        id: 'church-1',
        name: 'Igreja Central',
        slug: 'igreja-central',
        email: 'contato@igreja.dev',
      ),
      relatedUnits: [
        ChurchUnitEntity(
          id: 'unit-1',
          churchId: 'church-1',
          name: 'Sede Central',
          slug: 'sede-central',
          type: 'MAIN',
        ),
        ChurchUnitEntity(
          id: 'unit-2',
          churchId: 'church-1',
          name: 'Filial Leste',
          slug: 'filial-leste',
          type: 'BRANCH',
        ),
      ],
    );
  }

  SessionPermissions buildPermissions(Affiliation affiliation) {
    return SessionPermissions(
      isAuthenticated: true,
      affiliation: affiliation,
      activeUnitId: 'unit-0',
      hasMembership: true,
      integrations: const [],
      isUnitAdmin: false,
    );
  }

  const authenticatedWithoutMembership = SessionPermissions(
    isAuthenticated: true,
    affiliation: null,
    activeUnitId: null,
    hasMembership: false,
    integrations: [],
    isUnitAdmin: false,
  );

  Widget buildScreen({
    required PublicChurchUnitProfileEntity profile,
    SessionPermissions? permissions,
    PendingMembershipEntity? pendingMembership,
    ChurchUnitRepository? churchUnitRepository,
  }) {
    return ProviderScope(
      overrides: [
        publicChurchUnitProfileProvider.overrideWith(
          (ref, unitId) async => profile,
        ),
        sessionPermissionsProvider.overrideWith(
          (ref) async => permissions ?? const SessionPermissions.empty(),
        ),
        if (pendingMembership != null)
          pendingMembershipForUnitProvider(
            pendingMembership.unitId,
          ).overrideWithValue(pendingMembership),
        if (pendingMembership == null)
          pendingMembershipForUnitProvider('unit-1').overrideWithValue(null),
        if (churchUnitRepository != null)
          churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
      ],
      child: const MaterialApp(home: ChurchInfoProfileScreen(unitId: 'unit-1')),
    );
  }

  testWidgets('shows loading state', (tester) async {
    final completer = Completer<PublicChurchUnitProfileEntity>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) => completer.future,
          ),
        ],
        child: const MaterialApp(
          home: ChurchInfoProfileScreen(unitId: 'unit-1'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders public profile with unit data', (tester) async {
    await tester.pumpWidget(buildScreen(profile: buildMainProfile()));
    await tester.pumpAndSettle();

    expect(find.text('Sede Central'), findsOneWidget);
    expect(find.text('@sede-central'), findsOneWidget);
    expect(find.text('Rua A, 10'), findsOneWidget);
    expect(find.text('(11) 99999-0000'), findsOneWidget);
    expect(find.text('sede@igreja.dev'), findsOneWidget);
    expect(find.text('Sede da rede'), findsOneWidget);
    expect(find.text('Filial Leste'), findsOneWidget);
    expect(find.byKey(ChurchFloatingBackButton.buttonKey), findsOneWidget);
  });

  testWidgets('falls back to church name and slug when unit is incomplete', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) async => PublicChurchUnitProfileEntity(
              unit: const ChurchUnitEntity(
                id: 'unit-1',
                churchId: 'church-1',
                email: 'sede@igreja.dev',
              ),
              church: const ChurchEntity(
                id: 'church-1',
                name: 'Igreja Central',
                slug: 'igreja-central',
                email: 'contato@igreja.dev',
              ),
              relatedUnits: const [],
            ),
          ),
        ],
        child: const MaterialApp(
          home: ChurchInfoProfileScreen(unitId: 'unit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Igreja Central'), findsOneWidget);
    expect(find.text('@igreja-central'), findsOneWidget);
  });

  testWidgets('shows join menu for visitor and congregated', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        profile: buildMainProfile(),
        permissions: buildPermissions(Affiliation.visitor),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('church-info-profile-join-menu-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      buildScreen(
        profile: buildMainProfile(),
        permissions: buildPermissions(Affiliation.congregated),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('church-info-profile-join-menu-button')),
      findsOneWidget,
    );
  });

  testWidgets('shows join menu for authenticated user without membership', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(
        profile: buildMainProfile(),
        permissions: authenticatedWithoutMembership,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('church-info-profile-join-menu-button')),
      findsOneWidget,
    );
  });

  testWidgets('hides join menu for member', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        profile: buildMainProfile(),
        permissions: buildPermissions(Affiliation.member),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('church-info-profile-join-menu-button')),
      findsNothing,
    );
  });

  testWidgets('disables only the pending affiliation for the current unit', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(
        profile: buildMainProfile(),
        permissions: buildPermissions(Affiliation.visitor),
        pendingMembership: const PendingMembershipEntity(
          id: 'pending-1',
          unitId: 'unit-1',
          personId: 'person-1',
          affiliation: 'CONGREGATED',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('church-info-profile-join-menu-button')),
    );
    await tester.pumpAndSettle();

    final congregatedItem = tester.widget<MenuItemButton>(
      find.widgetWithText(MenuItemButton, 'Vincular-se como congregado'),
    );
    final memberItem = tester.widget<MenuItemButton>(
      find.widgetWithText(MenuItemButton, 'Vincular-se como membro'),
    );

    expect(congregatedItem.onPressed, isNull);
    expect(memberItem.onPressed, isNotNull);
  });

  testWidgets('shows mock visitor snackbar from the join menu', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        profile: buildMainProfile(),
        permissions: buildPermissions(Affiliation.visitor),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('church-info-profile-join-menu-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como visitante'));
    await tester.pumpAndSettle();

    expect(
      find.text('A entrada como visitante ainda não está disponível.'),
      findsOneWidget,
    );
  });

  testWidgets('confirms join request and shows success feedback', (
    tester,
  ) async {
    final repository = _MockChurchUnitRepository();
    when(
      () => repository.joinUnit('unit-1', 'CONGREGATED'),
    ).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(
      buildScreen(
        profile: buildMainProfile(),
        permissions: buildPermissions(Affiliation.visitor),
        churchUnitRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('church-info-profile-join-menu-button')),
    );
    await tester.pumpAndSettle();

    final joinItem = tester.widget<MenuItemButton>(
      find.widgetWithText(MenuItemButton, 'Vincular-se como congregado'),
    );
    joinItem.onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    verify(() => repository.joinUnit('unit-1', 'CONGREGATED')).called(1);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('branch profile links back to headquarter', (tester) async {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) =>
              const ChurchInfoProfileScreen(unitId: 'unit-2'),
        ),
        GoRoute(
          path: AppRoutes.churchPublicProfile,
          name: AppRoutes.churchPublicProfileName,
          builder: (context, state) =>
              Text('opened:${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) async => buildBranchProfile(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver unidade sede'), findsOneWidget);

    await tester.tap(find.text('Ver unidade sede'));
    await tester.pumpAndSettle();

    expect(find.text('opened:unit-1'), findsOneWidget);
  });

  testWidgets('shows error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) => Future<PublicChurchUnitProfileEntity>.error(
              const NetworkFailure('Falha'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ChurchInfoProfileScreen(unitId: 'unit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar o perfil da igreja.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
