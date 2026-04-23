import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/router/app_router.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockDepartmentRepository departmentRepository;
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
    integrations: [],
    isUnitAdmin: false,
  );

  setUp(() {
    authRepository = _MockAuthRepository();
    departmentRepository = _MockDepartmentRepository();

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
    when(() => departmentRepository.getParticipants('dep-1')).thenAnswer(
      (_) async => const Right(<DepartmentParticipantEntity>[]),
    );

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
        departmentRepositoryProvider.overrideWithValue(departmentRepository),
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
}
