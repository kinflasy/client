import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/screens/department_screen.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
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
          membershipId: 'membership-1',
          integrationType: IntegrationType.integrant,
          nickname: 'Maria',
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
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) async => const [],
          ),
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
    expect(find.text('Integrantes'), findsOneWidget);
    expect(find.text('Nenhum evento encontrado.'), findsOneWidget);

    await tester.tap(find.text('Integrantes'));
    await tester.pumpAndSettle();

    expect(find.text('Maria'), findsOneWidget);
    expect(find.textContaining('34 anos'), findsOneWidget);
    expect(find.text('Adicionar integrantes'), findsOneWidget);
  });

  testWidgets('shows department events empty state', (tester) async {
    _stubDepartmentDetail(repository);
    _stubParticipants(repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) async => const [],
          ),
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

    expect(find.text('Nenhum evento encontrado.'), findsOneWidget);
    expect(find.text('Criar evento'), findsOneWidget);
  });

  testWidgets('scales tab shows create button only for manager', (
    tester,
  ) async {
    await _pumpScaleTab(
      tester: tester,
      repository: repository,
      permissions: _leaderPermissions,
    );

    expect(find.text('Nova escala'), findsOneWidget);
    expect(find.text('Nenhuma escala cadastrada ainda.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await _pumpScaleTab(
      tester: tester,
      repository: repository,
      permissions: _integrantPermissions,
    );

    expect(find.text('Nova escala'), findsNothing);
    expect(find.text('Nenhuma escala cadastrada ainda.'), findsOneWidget);
  });

  testWidgets('scales tab shows create button for assistant and unit admin', (
    tester,
  ) async {
    await _pumpScaleTab(
      tester: tester,
      repository: repository,
      permissions: _assistantPermissions,
    );

    expect(find.text('Nova escala'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await _pumpScaleTab(
      tester: tester,
      repository: repository,
      permissions: _unitAdminPermissions,
    );

    expect(find.text('Nova escala'), findsOneWidget);
  });

  testWidgets('scales tab shows loading state', (tester) async {
    final completer = Completer<List<DepartmentScaleWithLineupEntity>>();

    await _pumpScaleTab(
      tester: tester,
      repository: repository,
      permissions: _leaderPermissions,
      scalesBuilder: (ref, request) => completer.future,
      settleAfterTabTap: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('scales tab shows loading error', (tester) async {
    await _pumpScaleTab(
      tester: tester,
      repository: repository,
      permissions: _leaderPermissions,
      scalesBuilder: (ref, request) =>
          Future.error(const NetworkFailure('Falha ao carregar escalas')),
    );

    expect(find.text('Não foi possível carregar as escalas.'), findsOneWidget);
    expect(find.text('Tente novamente em instantes.'), findsOneWidget);
  });

  testWidgets('scales tab navigates to scale detail on card tap', (
    tester,
  ) async {
    Object? capturedExtra;
    await _pumpScaleTabWithRouter(
      tester: tester,
      repository: repository,
      permissions: _leaderPermissions,
      scales: [_departmentScale],
      detailBuilder: (context, state) {
        capturedExtra = state.extra;
        return Scaffold(
          body: Text(
            'Detalhe ${state.pathParameters['departmentId']} ${state.pathParameters['scaleId']}',
          ),
        );
      },
    );

    expect(find.text('Culto da manhã'), findsOneWidget);
    expect(find.text('Dom, 19 jul - 09:00'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.text('Culto da manhã'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe dep-1 scale-1'), findsOneWidget);
    expect(capturedExtra, same(_departmentScale));
  });

  testWidgets('scales tab renders lineup function in card', (tester) async {
    await _pumpScaleTab(
      tester: tester,
      repository: repository,
      permissions: _leaderPermissions,
      scales: [
        _departmentScaleWithLineup([
          const LineupItemEntity(
            id: 'item-1',
            lineupId: 'lineup-1',
            roleId: 'role-1',
            description: 'Voz principal',
            role: RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
          ),
        ]),
      ],
    );

    expect(find.text('Culto da manhã'), findsOneWidget);
    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Voz principal'), findsNothing);
  });

  testWidgets('scales tab keeps card visible when lineup partially fails', (
    tester,
  ) async {
    await _pumpScaleTab(
      tester: tester,
      repository: repository,
      permissions: _leaderPermissions,
      scales: [_departmentScaleWithFailure],
    );

    expect(find.text('Culto da manhã'), findsOneWidget);
    expect(find.text('Vocal'), findsNothing);
    expect(find.text('Nenhuma função definida'), findsNothing);
  });

  testWidgets(
    'opens settings sidebar with scale formations option for observer',
    (tester) async {
      _stubDepartmentDetail(repository);
      _stubParticipants(repository);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            departmentRepositoryProvider.overrideWithValue(repository),
            departmentCalendarEventsProvider.overrideWith(
              (ref, request) async => const [],
            ),
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

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.text('Formações de escala'), findsOneWidget);
    },
  );

  testWidgets('shows department events rendered with EventCard', (
    tester,
  ) async {
    _stubDepartmentDetail(repository);
    _stubParticipants(repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) async => [_departmentEvent],
          ),
          calendarEventDetailProvider.overrideWith(
            (ref, eventId) async => _departmentEvent,
          ),
          calendarEventCollaboratorsProvider.overrideWith(
            (ref, eventId) async => const [],
          ),
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

    expect(find.text('Ensaio do Louvor'), findsOneWidget);
    expect(find.text('12 mai 19:00 - 12 mai 21:00'), findsOneWidget);
    expect(find.text('Preparação do domingo'), findsOneWidget);
    expect(find.text('Unidade - Louvor'), findsOneWidget);
  });

  testWidgets('opens event detail bottom sheet from department event card', (
    tester,
  ) async {
    _stubDepartmentDetail(repository);
    _stubParticipants(repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) async => [_departmentEvent],
          ),
          calendarEventDetailProvider.overrideWith(
            (ref, eventId) async => _departmentEvent,
          ),
          calendarEventCollaboratorsProvider.overrideWith(
            (ref, eventId) async => const [],
          ),
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

    await tester.tap(find.text('Ensaio do Louvor'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('Ensaio do Louvor'), findsNWidgets(2));
  });

  testWidgets('shows department events loading error', (tester) async {
    _stubDepartmentDetail(repository);
    _stubParticipants(repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) => Future.error(Exception('falha')),
          ),
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

    expect(find.text('Não foi possível carregar os eventos.'), findsOneWidget);
    expect(find.text('Tente novamente em instantes.'), findsOneWidget);
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
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) async => const [],
          ),
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
    expect(find.text('Integrantes'), findsOneWidget);
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
          membershipId: 'membership-1',
          integrationType: IntegrationType.integrant,
          nickname: 'Maria',
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
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) async => const [],
          ),
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

    await tester.tap(find.text('Integrantes'));
    await tester.pumpAndSettle();

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Adicionar integrantes'), findsNothing);
  });

  testWidgets('shows add participants button for assistant', (tester) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _assistantPermissions,
    );

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Adicionar integrantes'), findsOneWidget);
  });

  testWidgets('opens participant bottom sheet from participant card', (
    tester,
  ) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _assistantPermissions,
      participants: const [
        DepartmentParticipantEntity(
          personId: 'person-1',
          membershipId: 'membership-1',
          integrationType: IntegrationType.integrant,
          nickname: 'Maria',
          phone: '(85) 99999-0000',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
          age: 34,
        ),
      ],
    );

    await tester.tap(find.text('Maria'));
    await tester.pumpAndSettle();

    expect(find.text('(85) 99999-0000'), findsOneWidget);
    expect(find.text('Integrante'), findsOneWidget);
  });

  testWidgets('passes profile image id to participant card', (tester) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _assistantPermissions,
      participants: const [
        DepartmentParticipantEntity(
          personId: 'person-1',
          membershipId: 'membership-1',
          integrationType: IntegrationType.integrant,
          nickname: 'Maria',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
          profileImageId: 'image-1',
        ),
      ],
      extraOverrides: [
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://cdn.example/$imageId.png',
        ),
      ],
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('uses username when participant nickname is blank', (
    tester,
  ) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _assistantPermissions,
      participants: const [
        DepartmentParticipantEntity(
          personId: 'person-1',
          membershipId: 'membership-1',
          integrationType: IntegrationType.integrant,
          nickname: ' ',
          username: 'maria.silva',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
        ),
      ],
    );

    expect(find.text('maria.silva'), findsOneWidget);
    expect(find.text('Maria'), findsNothing);
  });

  testWidgets('uses neutral label without nickname or username', (
    tester,
  ) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _assistantPermissions,
      participants: const [
        DepartmentParticipantEntity(
          personId: 'person-1',
          membershipId: 'membership-1',
          integrationType: IntegrationType.integrant,
          affiliation: 'MEMBER',
          gender: 'FEMALE',
        ),
      ],
    );

    expect(find.text('Integrante'), findsOneWidget);
  });

  testWidgets('shows add participants button for unit admin', (tester) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _unitAdminPermissions,
    );

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Adicionar integrantes'), findsOneWidget);
  });

  testWidgets('shows create event button and event menu for leader', (
    tester,
  ) async {
    _stubDepartmentDetail(repository);
    _stubParticipants(repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) async => [_departmentEvent],
          ),
          calendarEventDetailProvider.overrideWith(
            (ref, eventId) async => _departmentEvent,
          ),
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

    expect(find.text('Criar evento'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('hides create event button and event menu for integrant', (
    tester,
  ) async {
    _stubDepartmentDetail(repository);
    _stubParticipants(repository);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(repository),
          departmentCalendarEventsProvider.overrideWith(
            (ref, request) async => [_departmentEvent],
          ),
          calendarEventDetailProvider.overrideWith(
            (ref, eventId) async => _departmentEvent,
          ),
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

    expect(find.text('Criar evento'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}

Future<void> _pumpParticipantsTab({
  required WidgetTester tester,
  required DepartmentRepository repository,
  required SessionPermissions permissions,
  List extraOverrides = const [],
  List<DepartmentParticipantEntity> participants = const [
    DepartmentParticipantEntity(
      personId: 'person-1',
      membershipId: 'membership-1',
      integrationType: IntegrationType.integrant,
      nickname: 'Maria',
      affiliation: 'MEMBER',
      gender: 'FEMALE',
      age: 34,
    ),
  ],
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
  when(
    () => repository.getParticipants('dep-1'),
  ).thenAnswer((_) async => Right(participants));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
        departmentCalendarEventsProvider.overrideWith(
          (ref, request) async => const [],
        ),
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
        ...extraOverrides,
      ],
      child: const MaterialApp(
        home: DepartmentScreen(departmentId: 'dep-1', showBackButton: true),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Integrantes'));
  await tester.pumpAndSettle();
}

Future<void> _pumpScaleTab({
  required WidgetTester tester,
  required DepartmentRepository repository,
  required SessionPermissions permissions,
  List<DepartmentScaleWithLineupEntity>? scales,
  Future<List<DepartmentScaleWithLineupEntity>> Function(
    Ref ref,
    DepartmentScalesRequest request,
  )?
  scalesBuilder,
  bool settleAfterTabTap = true,
}) async {
  _stubDepartmentDetail(repository);
  _stubParticipants(repository);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
        departmentCalendarEventsProvider.overrideWith(
          (ref, request) async => const [],
        ),
        departmentScalesWithLineupsProvider.overrideWith(
          scalesBuilder ?? (ref, request) async => scales ?? const [],
        ),
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
      ],
      child: const MaterialApp(
        home: DepartmentScreen(departmentId: 'dep-1', showBackButton: true),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Escalas'));
  await tester.pump();
  if (settleAfterTabTap) {
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpScaleTabWithRouter({
  required WidgetTester tester,
  required DepartmentRepository repository,
  required SessionPermissions permissions,
  required List<DepartmentScaleWithLineupEntity> scales,
  required Widget Function(BuildContext context, GoRouterState state)
  detailBuilder,
}) async {
  _stubDepartmentDetail(repository);
  _stubParticipants(repository);

  final router = GoRouter(
    initialLocation: '/departamentos/dep-1',
    routes: [
      GoRoute(
        path: AppRoutes.departmentDetail,
        builder: (context, state) =>
            const DepartmentScreen(departmentId: 'dep-1', showBackButton: true),
      ),
      GoRoute(
        path: AppRoutes.departmentScaleDetail,
        name: AppRoutes.departmentScaleDetailName,
        builder: detailBuilder,
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        departmentRepositoryProvider.overrideWithValue(repository),
        departmentCalendarEventsProvider.overrideWith(
          (ref, request) async => const [],
        ),
        departmentScalesWithLineupsProvider.overrideWith(
          (ref, request) async => scales,
        ),
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Escalas'));
  await tester.pumpAndSettle();
}

void _stubDepartmentDetail(DepartmentRepository repository) {
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
}

void _stubParticipants(DepartmentRepository repository) {
  when(() => repository.getParticipants('dep-1')).thenAnswer(
    (_) async => const Right([
      DepartmentParticipantEntity(
        personId: 'person-1',
        membershipId: 'membership-1',
        integrationType: IntegrationType.integrant,
        nickname: 'Maria',
        affiliation: 'MEMBER',
        gender: 'FEMALE',
        age: 34,
      ),
    ]),
  );
}

final _departmentEvent = CalendarEventEntity(
  id: 'event-1',
  title: 'Ensaio do Louvor',
  description: 'Preparação do domingo',
  startDateTime: DateTime(2026, 5, 12, 19),
  endDateTime: DateTime(2026, 5, 12, 21),
  type: CalendarEventType.department,
  departmentId: 'dep-1',
);

final _departmentScale = DepartmentScaleWithLineupEntity(
  lineupState: DepartmentScaleLineupLoadState.loaded,
  scale: DepartmentCalendarEventScaleEntity(
    scale: const CalendarEventScaleEntity(
      id: 'scale-1',
      lineupId: 'lineup-1',
      type: CalendarEventScaleType.owner,
      calendarEventId: 'event-scale-1',
    ),
    calendarEvent: CalendarEventEntity(
      id: 'event-scale-1',
      title: 'Culto da manhã',
      startDateTime: DateTime(2026, 7, 19, 9),
      endDateTime: DateTime(2026, 7, 19, 11),
      type: CalendarEventType.department,
      departmentId: 'dep-1',
    ),
  ),
);

final _departmentScaleWithFailure = DepartmentScaleWithLineupEntity(
  lineupState: DepartmentScaleLineupLoadState.failed,
  scale: _departmentScale.scale,
);

DepartmentScaleWithLineupEntity _departmentScaleWithLineup(
  List<LineupItemEntity> items,
) {
  return DepartmentScaleWithLineupEntity(
    scale: _departmentScale.scale,
    lineupState: DepartmentScaleLineupLoadState.loaded,
    lineup: LineupEntity(id: 'lineup-1', name: 'Banda', items: items),
  );
}
