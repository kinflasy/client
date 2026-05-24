import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/core/router/app_router.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/sub_features/create_event/presentation/screens/create_event_screen.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/my_departments_unit_group.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockDepartmentRepository departmentRepository;
  late _MockChurchUnitRepository churchUnitRepository;
  late ProviderContainer container;

  const user = UserEntity(
    id: 'user-1',
    username: 'lisa',
    email: 'lisa@example.com',
    fullName: 'Lisa Silva',
  );

  const permissions = SessionPermissions(
    isAuthenticated: true,
    affiliation: Affiliation.member,
    activeUnitId: 'unit-1',
    hasMembership: true,
    integrations: [
      IntegrationEntity(
        id: 'integration-1',
        membershipId: 'membership-1',
        departmentId: 'dep-1',
        departmentType: 'MINISTRY',
        integrationType: IntegrationType.integrant,
      ),
    ],
    isUnitAdmin: false,
  );

  const adminPermissions = SessionPermissions(
    isAuthenticated: true,
    affiliation: Affiliation.unitAdmin,
    activeUnitId: 'unit-1',
    hasMembership: true,
    integrations: [],
    isUnitAdmin: true,
  );

  const leaderPermissions = SessionPermissions(
    isAuthenticated: true,
    affiliation: Affiliation.member,
    activeUnitId: 'unit-1',
    hasMembership: true,
    integrations: [
      IntegrationEntity(
        id: 'integration-2',
        membershipId: 'membership-1',
        departmentId: 'dep-1',
        departmentType: 'MINISTRY',
        integrationType: IntegrationType.leader,
      ),
    ],
    isUnitAdmin: false,
  );

  setUp(() {
    authRepository = _MockAuthRepository();
    departmentRepository = _MockDepartmentRepository();
    churchUnitRepository = _MockChurchUnitRepository();

    when(() => authRepository.getCurrentUser()).thenAnswer((_) async => user);
    when(() => departmentRepository.getDepartmentById('dep-1')).thenAnswer(
      (_) async => const Right(
        DepartmentDetailEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
      ),
    );
    when(
      () => departmentRepository.getParticipants('dep-1'),
    ).thenAnswer((_) async => const Right(<DepartmentParticipantEntity>[]));
    when(() => departmentRepository.getDepartmentById('dep-2')).thenAnswer(
      (_) async => const Right(
        DepartmentDetailEntity(
          id: 'dep-2',
          name: 'Midia',
          slug: 'midia',
          type: 'MINISTRY',
        ),
      ),
    );
    when(
      () => departmentRepository.getParticipants('dep-2'),
    ).thenAnswer((_) async => const Right(<DepartmentParticipantEntity>[]));
    when(() => departmentRepository.getLineupWithItems('lineup-1')).thenAnswer(
      (_) async => const Right(LineupEntity(id: 'lineup-1', name: 'Culto')),
    );
    when(
      () => churchUnitRepository.getPendingMembers('unit-1'),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => departmentRepository.getDepartmentsByUnitId('unit-1'),
    ).thenAnswer(
      (_) async => const Right([
        DepartmentEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
        DepartmentEntity(
          id: 'dep-2',
          name: 'Midia',
          slug: 'midia',
          type: 'MINISTRY',
        ),
        DepartmentEntity(
          id: 'dep-3',
          name: 'Secretaria',
          slug: 'secretaria',
          type: 'ADMINISTRATIVE',
        ),
      ]),
    );

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
        hasMembershipProvider.overrideWith((ref) => true),
        editLoggedUserInitialDataProvider.overrideWith(
          (ref) async => _loggedUserProfile(),
        ),
        pendingUnitMembershipsProvider.overrideWith(
          (ref, unitId) async => const [],
        ),
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        departmentCalendarEventsProvider.overrideWith(
          (ref, request) async => const [],
        ),
        calendarEventDetailProvider(
          'event-1',
        ).overrideWith((ref) async => _routerEvent()),
        myDepartmentsByUnitProvider.overrideWith(
          (ref) async => const [
            MyDepartmentsUnitGroup(
              unitId: 'unit-1',
              unitName: 'Igreja Batista Betel',
              departments: [
                DepartmentEntity(
                  id: 'dep-2',
                  name: 'Midia',
                  slug: 'midia',
                  type: 'MINISTRY',
                ),
              ],
            ),
          ],
        ),
        rawUnitMembersProvider.overrideWith((ref, unitId) async => const []),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpRouter(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  testWidgets('shell department detail keeps bottom navigation visible', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go('/home/church/departamentos/dep-1');
    await pumpRouter(tester);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Louvor'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('standalone department detail hides bottom navigation', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go('/departamentos/dep-1');
    await pumpRouter(tester);

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Louvor'), findsOneWidget);
  });

  testWidgets('department participants add route opens outside shell', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go('/departamentos/dep-1/participantes/adicionar');
    await tester.pump();
    await pumpRouter(tester);

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Pesquisar nome ou apelido...'), findsOneWidget);
  });

  testWidgets(
    'department lineups route opens with department observer access',
    (tester) async {
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpRouter(tester);

      router.goNamed(
        AppRoutes.departmentLineupsName,
        pathParameters: {'id': 'dep-1'},
      );
      await tester.pump();
      await pumpRouter(tester);

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.text('Escalas'), findsOneWidget);
    },
  );

  testWidgets('user without department access is redirected from lineups', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go('/departamentos/dep-2/escalas');
    await pumpRouter(tester);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Escalas'), findsNothing);
  });

  testWidgets(
    'user without department access is redirected from lineup detail',
    (tester) async {
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpRouter(tester);

      router.go('/departamentos/dep-2/escalas/lineup-1');
      await pumpRouter(tester);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Culto'), findsNothing);
    },
  );

  testWidgets('department event create route opens for department leader', (
    tester,
  ) async {
    final leaderContainer = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionPermissionsProvider.overrideWith(
          (ref) async => leaderPermissions,
        ),
        hasMembershipProvider.overrideWith((ref) => true),
        editLoggedUserInitialDataProvider.overrideWith(
          (ref) async => _loggedUserProfile(),
        ),
        pendingUnitMembershipsProvider.overrideWith(
          (ref, unitId) async => const [],
        ),
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        calendarEventDetailProvider(
          'event-1',
        ).overrideWith((ref) async => _routerEvent()),
      ],
    );
    addTearDown(leaderContainer.dispose);

    final router = leaderContainer.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: leaderContainer,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    router.goNamed('department-event-create', pathParameters: {'id': 'dep-1'});
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Criar evento'), findsOneWidget);
    expect(find.text('Organizado por *'), findsNothing);
  });

  testWidgets(
    'admin calendar duplicate route opens create screen with source id',
    (tester) async {
      expect(
        AppRoutes.adminCalendarDuplicate,
        '/admin/calendario/:id/duplicar',
      );
      expect(AppRoutes.adminCalendarDuplicateName, 'admin-calendar-duplicate');

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      router.goNamed(
        AppRoutes.adminCalendarDuplicateName,
        pathParameters: {'id': 'event-1'},
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CreateEventScreen &&
              widget.duplicateFromEventId == 'event-1' &&
              widget.eventId == null,
        ),
        findsOneWidget,
      );
      expect(find.text('Duplicar evento'), findsOneWidget);
    },
  );

  testWidgets(
    'department leader is not blocked before opening duplicate route',
    (tester) async {
      final leaderContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          sessionPermissionsProvider.overrideWith(
            (ref) async => leaderPermissions,
          ),
          hasMembershipProvider.overrideWith((ref) => true),
          editLoggedUserInitialDataProvider.overrideWith(
            (ref) async => _loggedUserProfile(),
          ),
          pendingUnitMembershipsProvider.overrideWith(
            (ref, unitId) async => const [],
          ),
          departmentRepositoryProvider.overrideWithValue(departmentRepository),
          churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-1',
              unitId: 'unit-1',
              affiliation: 'MEMBER',
            ),
          ),
          currentChurchProfileProvider.overrideWith((ref) async => _profile()),
          calendarEventDetailProvider(
            'event-1',
          ).overrideWith((ref) async => _routerEvent()),
        ],
      );
      addTearDown(leaderContainer.dispose);

      final router = leaderContainer.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: leaderContainer,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      router.goNamed(
        AppRoutes.adminCalendarDuplicateName,
        pathParameters: {'id': 'event-1'},
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Duplicar evento'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    },
  );

  testWidgets('integrant is redirected away from department event create', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    router.go('/departamentos/dep-1/eventos/criar');
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Criar evento'), findsNothing);
  });

  testWidgets('department leader can open lineup create route', (tester) async {
    final leaderContainer = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionPermissionsProvider.overrideWith(
          (ref) async => leaderPermissions,
        ),
        hasMembershipProvider.overrideWith((ref) => true),
        editLoggedUserInitialDataProvider.overrideWith(
          (ref) async => _loggedUserProfile(),
        ),
        pendingUnitMembershipsProvider.overrideWith(
          (ref, unitId) async => const [],
        ),
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
      ],
    );
    addTearDown(leaderContainer.dispose);

    final router = leaderContainer.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: leaderContainer,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    router.go('/departamentos/dep-1/escalas/criar');
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Novo lineup'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('integrant is redirected away from lineup create route', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    router.go('/departamentos/dep-1/escalas/criar');
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Novo lineup'), findsNothing);
  });

  testWidgets('integrant can open lineup detail route without edit chrome', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    router.go('/departamentos/dep-1/escalas/lineup-1');
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Culto'), findsWidgets);
    expect(find.text('Editar nome'), findsNothing);
  });

  testWidgets(
    'shell department category list keeps bottom navigation visible',
    (tester) async {
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpRouter(tester);

      router.go('/home/church/departamentos/categoria/general');
      await pumpRouter(tester);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Geral'), findsOneWidget);
      expect(find.text('Buscar departamento por nome'), findsOneWidget);
    },
  );

  testWidgets(
    'shell my departments menu screen keeps bottom navigation visible',
    (tester) async {
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpRouter(tester);

      router.go('/home/menu/meus-departamentos');
      await pumpRouter(tester);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Meus departamentos'), findsOneWidget);
      expect(find.text('Igreja Batista Betel'), findsOneWidget);
    },
  );

  testWidgets('menu edit profile route opens logged user profile summary', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go(AppRoutes.homeMenuEditProfile);
    await pumpRouter(tester);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Meu perfil'), findsOneWidget);
  });

  testWidgets('menu edit profile info subroute opens textual edit screen', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go(AppRoutes.homeMenuEditProfileInfo);
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Editar dados pessoais'), findsOneWidget);
  });

  testWidgets('menu edit profile address subroute opens address edit screen', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go(AppRoutes.homeMenuEditProfileAddress);
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Editar endereço'), findsOneWidget);
  });

  testWidgets(
    'user without integration is redirected away from department detail',
    (tester) async {
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpRouter(tester);

      router.go('/departamentos/dep-2');
      await pumpRouter(tester);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Midia'), findsNothing);
    },
  );

  testWidgets(
    'non admin user is redirected away from membership requests route',
    (tester) async {
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpRouter(tester);

      router.go('/admin/membros/solicitacoes');
      await pumpRouter(tester);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    },
  );

  testWidgets('unit admin user can access membership requests route', (
    tester,
  ) async {
    final adminContainer = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionPermissionsProvider.overrideWith(
          (ref) async => adminPermissions,
        ),
        hasMembershipProvider.overrideWith((ref) => true),
        editLoggedUserInitialDataProvider.overrideWith(
          (ref) async => _loggedUserProfile(),
        ),
        pendingUnitMembershipsProvider.overrideWith(
          (ref, unitId) async => const [],
        ),
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'UNIT_ADMIN',
          ),
        ),
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        departmentCalendarEventsProvider.overrideWith(
          (ref, request) async => const [],
        ),
      ],
    );
    addTearDown(adminContainer.dispose);

    final router = adminContainer.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: adminContainer,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go('/admin/membros/solicitacoes');
    await pumpRouter(tester);

    expect(find.text('Solicita\u00e7\u00f5es de v\u00ednculo'), findsOneWidget);
    expect(
      find.text('Nenhuma solicita\u00e7\u00e3o pendente.'),
      findsOneWidget,
    );
  });

  testWidgets('non admin user is redirected away from general info route', (
    tester,
  ) async {
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go('/admin/informacoes-gerais');
    await pumpRouter(tester);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('unit admin user can access general info route', (tester) async {
    final adminContainer = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionPermissionsProvider.overrideWith(
          (ref) async => adminPermissions,
        ),
        hasMembershipProvider.overrideWith((ref) => true),
        editLoggedUserInitialDataProvider.overrideWith(
          (ref) async => _loggedUserProfile(),
        ),
        pendingUnitMembershipsProvider.overrideWith(
          (ref, unitId) async => const [],
        ),
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'UNIT_ADMIN',
          ),
        ),
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        departmentCalendarEventsProvider.overrideWith(
          (ref, request) async => const [],
        ),
      ],
    );
    addTearDown(adminContainer.dispose);

    final router = adminContainer.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: adminContainer,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go('/admin/informacoes-gerais');
    await pumpRouter(tester);

    expect(find.text('Informações gerais'), findsOneWidget);
  });

  testWidgets('unit admin user can access any department detail', (
    tester,
  ) async {
    final adminContainer = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionPermissionsProvider.overrideWith(
          (ref) async => adminPermissions,
        ),
        hasMembershipProvider.overrideWith((ref) => true),
        editLoggedUserInitialDataProvider.overrideWith(
          (ref) async => _loggedUserProfile(),
        ),
        pendingUnitMembershipsProvider.overrideWith(
          (ref, unitId) async => const [],
        ),
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'UNIT_ADMIN',
          ),
        ),
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        departmentCalendarEventsProvider.overrideWith(
          (ref, request) async => const [],
        ),
      ],
    );
    addTearDown(adminContainer.dispose);

    final router = adminContainer.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: adminContainer,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpRouter(tester);

    router.go('/departamentos/dep-2');
    await pumpRouter(tester);

    expect(find.text('Midia'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}

CurrentChurchProfileEntity _profile() {
  return const CurrentChurchProfileEntity(
    membership: MembershipEntity(
      id: 'membership-1',
      unitId: 'unit-1',
      affiliation: 'MEMBER',
    ),
    unit: ChurchUnitEntity(id: 'unit-1', churchId: 'church-1'),
    church: ChurchEntity(
      id: 'church-1',
      name: 'Igreja Pontis',
      slug: 'igreja-pontis',
      email: 'contato@pontis.test',
    ),
  );
}

LoggedUserProfileEntity _loggedUserProfile() {
  return const LoggedUserProfileEntity(
    id: 'user-1',
    fullName: 'Lisa Silva',
    nickname: 'Lisa',
    gender: 'FEMALE',
    email: 'lisa@example.com',
  );
}

CalendarEventEntity _routerEvent() {
  return CalendarEventEntity(
    id: 'event-1',
    title: 'Culto especial',
    description: 'Celebração com toda a unidade.',
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: CalendarEventType.department,
    departmentId: 'dep-1',
  );
}
