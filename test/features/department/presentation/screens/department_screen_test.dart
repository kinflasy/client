import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
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
    expect(find.text('Participantes'), findsOneWidget);
    expect(find.text('Nenhum evento encontrado.'), findsOneWidget);

    await tester.tap(find.text('Participantes'));
    await tester.pumpAndSettle();

    expect(find.text('Maria'), findsOneWidget);
    expect(find.textContaining('34 anos'), findsOneWidget);
    expect(find.text('Adicionar participantes'), findsOneWidget);
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
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Participantes'));
    await tester.pumpAndSettle();

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Adicionar participantes'), findsNothing);
  });

  testWidgets('shows add participants button for assistant', (tester) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _assistantPermissions,
    );

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Adicionar participantes'), findsOneWidget);
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
          affiliation: 'MEMBER',
          gender: 'FEMALE',
        ),
      ],
    );

    expect(find.text('Participante'), findsOneWidget);
  });

  testWidgets('shows add participants button for unit admin', (tester) async {
    await _pumpParticipantsTab(
      tester: tester,
      repository: repository,
      permissions: _unitAdminPermissions,
    );

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Adicionar participantes'), findsOneWidget);
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
  List<DepartmentParticipantEntity> participants = const [
    DepartmentParticipantEntity(
      personId: 'person-1',
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
