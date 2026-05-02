import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/router/app_router.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/entities/my_departments_unit_group.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
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
    when(
      () => churchUnitRepository.getPendingMembers('unit-1'),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => departmentRepository.getDepartmentsByUnitId('unit-1'),
    ).thenAnswer(
      (_) async => const Right([
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
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
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
    await tester.pumpAndSettle();

    router.go('/home/church/departamentos/dep-1');
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    router.go('/departamentos/dep-1');
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    router.go('/departamentos/dep-1/participantes/adicionar');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Pesquisar nome ou apelido...'), findsOneWidget);
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
      await tester.pumpAndSettle();

      router.go('/home/church/departamentos/categoria/general');
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      router.go('/home/menu/meus-departamentos');
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Meus departamentos'), findsOneWidget);
      expect(find.text('Igreja Batista Betel'), findsOneWidget);
    },
  );

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
      await tester.pumpAndSettle();

      router.go('/departamentos/dep-2');
      await tester.pumpAndSettle();

      expect(find.textContaining('Feed'), findsOneWidget);
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
      await tester.pumpAndSettle();

      router.go('/admin/membros/solicitacoes');
      await tester.pumpAndSettle();

      expect(find.textContaining('Feed'), findsOneWidget);
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
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'UNIT_ADMIN',
          ),
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
    await tester.pumpAndSettle();

    router.go('/admin/membros/solicitacoes');
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    router.go('/admin/informacoes-gerais');
    await tester.pumpAndSettle();

    expect(find.textContaining('Feed'), findsOneWidget);
  });

  testWidgets('unit admin user can access general info route', (tester) async {
    final adminContainer = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionPermissionsProvider.overrideWith(
          (ref) async => adminPermissions,
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
    await tester.pumpAndSettle();

    router.go('/admin/informacoes-gerais');
    await tester.pumpAndSettle();

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
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
        churchUnitRepositoryProvider.overrideWithValue(churchUnitRepository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'UNIT_ADMIN',
          ),
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
    await tester.pumpAndSettle();

    router.go('/departamentos/dep-2');
    await tester.pumpAndSettle();

    expect(find.text('Midia'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
