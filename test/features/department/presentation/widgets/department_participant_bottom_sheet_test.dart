import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/widgets/department_participant_bottom_sheet.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _FakeIntegrationRequestModel extends Fake
    implements IntegrationRequestModel {}

const _participant = DepartmentParticipantEntity(
  personId: 'person-1',
  membershipId: 'membership-1',
  integrationType: IntegrationType.leader,
  nickname: 'Maria',
  phone: '(85) 99999-0000',
  profileImageId: 'image-1',
  affiliation: 'MEMBER',
  gender: 'FEMALE',
);

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

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeIntegrationRequestModel());
  });

  testWidgets(
    'renders nickname, phone, role and avatar from participant payload',
    (tester) async {
      await _pumpSheet(tester);
      await tester.pump();

      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('(85) 99999-0000'), findsOneWidget);
      expect(find.text('Líder'), findsWidgets);
      expect(find.byType(UserAvatar), findsOneWidget);
    },
  );

  testWidgets('keeps layout valid when phone is absent', (tester) async {
    await _pumpSheet(
      tester,
      participant: const DepartmentParticipantEntity(
        personId: 'person-1',
        membershipId: 'membership-1',
        integrationType: IntegrationType.leader,
        nickname: 'Maria',
        affiliation: 'MEMBER',
        gender: 'FEMALE',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Líder'), findsWidgets);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
  });

  test('translates all integration roles', () {
    expect(translateIntegrationType(IntegrationType.observer), 'Observador');
    expect(translateIntegrationType(IntegrationType.consultant), 'Consultor');
    expect(translateIntegrationType(IntegrationType.integrant), 'Integrante');
    expect(translateIntegrationType(IntegrationType.assistant), 'Assistente');
    expect(translateIntegrationType(IntegrationType.leader), 'Líder');
  });

  testWidgets('shows role selector only for editor', (tester) async {
    await _pumpSheet(tester, permissions: _leaderPermissions);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Papel no ministério'), findsOneWidget);
    expect(find.text('Salvar papel'), findsOneWidget);
  });

  testWidgets('assistant sees removal but not role selector', (tester) async {
    await _pumpSheet(tester, permissions: _assistantPermissions);
    await tester.pumpAndSettle();

    expect(find.text('Papel no ministério'), findsNothing);
    expect(find.text('Retirar do ministério'), findsOneWidget);
  });

  testWidgets('updates role and shows success feedback', (tester) async {
    final repository = _MockDepartmentRepository();
    when(
      () => repository.updateParticipantRole('dep-1', any()),
    ).thenAnswer((_) async => const Right(unit));

    await _pumpSheet(tester, repository: repository);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Líder').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistente').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar papel'));
    await tester.pumpAndSettle();

    expect(find.text('Papel atualizado.'), findsOneWidget);
  });

  testWidgets('keeps sheet open when role update fails', (tester) async {
    final repository = _MockDepartmentRepository();
    when(
      () => repository.updateParticipantRole('dep-1', any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha ao alterar.')));

    await _pumpSheet(tester, repository: repository);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Líder').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistente').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar papel'));
    await tester.pumpAndSettle();

    expect(find.text('Papel no ministério'), findsOneWidget);
    expect(find.text('Falha ao alterar.'), findsOneWidget);
  });

  testWidgets('requires confirmation before removal', (tester) async {
    final repository = _MockDepartmentRepository();
    when(
      () => repository.removeParticipant('dep-1', any()),
    ).thenAnswer((_) async => const Right(unit));

    await _pumpSheet(
      tester,
      permissions: _assistantPermissions,
      repository: repository,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retirar do ministério'));
    await tester.pumpAndSettle();

    expect(
      find.text('Tem certeza que deseja retirar esta pessoa do ministério?'),
      findsOneWidget,
    );
    verifyNever(() => repository.removeParticipant('dep-1', any()));
  });

  testWidgets('removes participant and closes sheet after confirmation', (
    tester,
  ) async {
    final repository = _MockDepartmentRepository();
    when(
      () => repository.removeParticipant('dep-1', any()),
    ).thenAnswer((_) async => const Right(unit));

    await _pumpSheet(
      tester,
      permissions: _assistantPermissions,
      repository: repository,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retirar do ministério'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();

    expect(find.text('Retirar do ministério'), findsNothing);
    expect(find.text('Integrante retirado do ministério.'), findsOneWidget);
  });

  testWidgets('keeps sheet open when removal fails', (tester) async {
    final repository = _MockDepartmentRepository();
    when(
      () => repository.removeParticipant('dep-1', any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha ao retirar.')));

    await _pumpSheet(
      tester,
      permissions: _assistantPermissions,
      repository: repository,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retirar do ministério'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();

    expect(find.text('Retirar do ministério'), findsOneWidget);
    expect(find.text('Falha ao retirar.'), findsOneWidget);
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  SessionPermissions permissions = _leaderPermissions,
  DepartmentParticipantEntity participant = _participant,
  DepartmentRepository? repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionPermissionsProvider.overrideWith((ref) async => permissions),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'active-membership',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
        if (repository != null)
          departmentRepositoryProvider.overrideWithValue(repository),
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://cdn.example/$imageId.png',
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDepartmentParticipantBottomSheet(
                  context,
                  departmentId: 'dep-1',
                  participant: participant,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir'));
  await tester.pump();
}
