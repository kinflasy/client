import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/screens/department_screen.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

const _leaderPermissions = SessionPermissions(
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
      integrationType: IntegrationType.leader,
    ),
  ],
  isUnitAdmin: false,
);

const _integrantPermissions = SessionPermissions(
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

const _assistantPermissions = SessionPermissions(
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
      integrationType: IntegrationType.assistant,
    ),
  ],
  isUnitAdmin: false,
);

const _unitAdminPermissions = SessionPermissions(
  isAuthenticated: true,
  affiliation: Affiliation.unitAdmin,
  activeUnitId: 'unit-1',
  hasMembership: true,
  integrations: [],
  isUnitAdmin: true,
);

void main() {
  late _MockDepartmentRepository repository;

  setUp(() {
    repository = _MockDepartmentRepository();
  });

  testWidgets('shows detail tabs and switches to participants list', (
    tester,
  ) async {
    when(() => repository.getDepartmentById('dep-1')).thenAnswer(
      (_) async => const Right(
        DepartmentDetailEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
      ),
    );
    when(() => repository.getParticipants('dep-1')).thenAnswer(
      (_) async => const Right([
        DepartmentParticipantEntity(
          personId: 'person-1',
          fullName: 'Maria Silva',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
          age: 34,
        ),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          sessionPermissionsProvider.overrideWith(
            (ref) async => _leaderPermissions,
          ),
        ],
        child: const MaterialApp(
          home: DepartmentScreen(departmentId: 'dep-1', showBackButton: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Participantes'), findsOneWidget);
    expect(find.text('Eventos do departamento em breve.'), findsOneWidget);

    await tester.tap(find.text('Participantes'));
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.textContaining('34 anos'), findsOneWidget);
    expect(find.text('Adicionar participantes'), findsOneWidget);
  });

  testWidgets('shows inline error when department detail fails', (
    tester,
  ) async {
    when(() => repository.getDepartmentById('dep-1')).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao carregar departamento')),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          sessionPermissionsProvider.overrideWith(
            (ref) async => _leaderPermissions,
          ),
        ],
        child: const MaterialApp(
          home: DepartmentScreen(departmentId: 'dep-1', showBackButton: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Departamento'), findsOneWidget);
    expect(
      find.text('Não foi possível carregar o departamento.'),
      findsOneWidget,
    );
    expect(find.text('Participantes'), findsNothing);
  });

  testWidgets('hides add participants button for user without management', (
    tester,
  ) async {
    when(() => repository.getDepartmentById('dep-1')).thenAnswer(
      (_) async => const Right(
        DepartmentDetailEntity(
          id: 'dep-1',
          name: 'Louvor',
          slug: 'louvor',
          type: 'MINISTRY',
        ),
      ),
    );
    when(() => repository.getParticipants('dep-1')).thenAnswer(
      (_) async => const Right([
        DepartmentParticipantEntity(
          personId: 'person-1',
          fullName: 'Maria Silva',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
          age: 34,
        ),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          sessionPermissionsProvider.overrideWith(
            (ref) async => _integrantPermissions,
          ),
        ],
        child: const MaterialApp(
          home: DepartmentScreen(departmentId: 'dep-1', showBackButton: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Participantes'));
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Adicionar participantes'), findsNothing);
  });

  testWidgets('shows add participants button for assistant', (tester) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _assistantPermissions,
    );

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Adicionar participantes'), findsOneWidget);
  });

  testWidgets('shows add participants button for unit admin', (tester) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _unitAdminPermissions,
    );

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Adicionar participantes'), findsOneWidget);
  });
}

Future<void> _pumpParticipantsTab({
  required WidgetTester tester,
  required DepartmentRepository repository,
  required SessionPermissions permissions,
}) async {
  when(() => repository.getDepartmentById('dep-1')).thenAnswer(
    (_) async => const Right(
      DepartmentDetailEntity(
        id: 'dep-1',
        name: 'Louvor',
        slug: 'louvor',
        type: 'MINISTRY',
      ),
    ),
  );
  when(() => repository.getParticipants('dep-1')).thenAnswer(
    (_) async => const Right([
      DepartmentParticipantEntity(
        personId: 'person-1',
        fullName: 'Maria Silva',
        affiliation: 'MEMBER',
        gender: 'FEMALE',
        age: 34,
      ),
    ]),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
      ],
      child: const MaterialApp(
        home: DepartmentScreen(departmentId: 'dep-1', showBackButton: true),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Participantes'));
  await tester.pumpAndSettle();
}
