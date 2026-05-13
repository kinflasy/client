import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/presentation/screens/department_participants_selection_screen.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

void main() {
  late _MockDepartmentRepository repository;

  final members = [
    const UnitMemberEntity(
      membershipId: 'membership-1',
      personId: 'person-1',
      fullName: 'Ana Mária',
      nickname: 'Aninha',
      affiliation: 'MEMBER',
      gender: 'FEMALE',
    ),
    const UnitMemberEntity(
      membershipId: 'membership-2',
      personId: 'person-2',
      fullName: 'Bruno Lima',
      affiliation: 'MEMBER',
      gender: 'MALE',
    ),
  ];

  setUpAll(() {
    registerFallbackValue(
      const IntegrationRequestModel(membershipId: 'fallback-membership'),
    );
  });

  setUp(() {
    repository = _MockDepartmentRepository();
  });

  testWidgets('renders loading state and search field', (tester) async {
    final completer = Completer<MembershipEntity?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMembershipProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(
          home: DepartmentParticipantsSelectionScreen(departmentId: 'dep-1'),
        ),
      ),
    );

    expect(find.text('Pesquisar nome ou apelido...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows selected member in horizontal strip', (tester) async {
    await _pumpScreen(tester, members);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Mária'), findsNWidgets(2));
    expect(find.byTooltip('Remover Ana Mária'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Adicionar 1'), findsOneWidget);
  });

  testWidgets('removing selected member from strip updates selection', (
    tester,
  ) async {
    await _pumpScreen(tester, members);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remover Ana Mária'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Mária'), findsOneWidget);
    expect(find.byTooltip('Remover Ana Mária'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text('Adicionar 0'), findsOneWidget);
  });

  testWidgets('tapping member again removes selection and updates counter', (
    tester,
  ) async {
    await _pumpScreen(tester, members);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar 1'), findsOneWidget);

    await tester.tap(find.text('Ana Mária').last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text('Adicionar 0'), findsOneWidget);
  });

  testWidgets('confirm button is disabled without selection', (tester) async {
    await _pumpScreen(tester, members);

    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Adicionar 0'),
        matching: find.byType(ElevatedButton),
      ),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('excludes current department participants from list', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      members,
      participants: const [
        DepartmentParticipantEntity(
          personId: 'person-1',
          nickname: 'Aninha',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
        ),
      ],
    );

    expect(find.text('Ana Mária'), findsNothing);
    expect(find.text('Bruno Lima'), findsOneWidget);
  });

  testWidgets('keeps unit member without integration available', (
    tester,
  ) async {
    await _pumpScreen(tester, members);

    expect(find.text('Bruno Lima'), findsOneWidget);
  });

  testWidgets('search finds by full name ignoring accents and case', (
    tester,
  ) async {
    await _pumpScreen(tester, members);

    await tester.enterText(find.byType(TextField), 'ana maria');
    await tester.pumpAndSettle();

    expect(find.text('Ana Mária'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsNothing);
  });

  testWidgets('search finds by nickname', (tester) async {
    await _pumpScreen(tester, members);

    await tester.enterText(find.byType(TextField), 'ANINHA');
    await tester.pumpAndSettle();

    expect(find.text('Ana Mária'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsNothing);
  });

  testWidgets('shows empty eligible state in Brazilian Portuguese', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      members,
      participants: const [
        DepartmentParticipantEntity(
          personId: 'person-1',
          nickname: 'Aninha',
          affiliation: 'MEMBER',
          gender: 'FEMALE',
        ),
        DepartmentParticipantEntity(
          personId: 'person-2',
          username: 'bruno.lima',
          affiliation: 'MEMBER',
          gender: 'MALE',
        ),
      ],
    );

    expect(
      find.text('Nenhuma pessoa disponível para adicionar.'),
      findsOneWidget,
    );
  });

  testWidgets('confirmation appears before submit', (tester) async {
    when(
      () => repository.addParticipant(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    await _pumpScreen(tester, members, repository: repository);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar 1'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar participantes'), findsOneWidget);
    expect(
      find.text('Deseja adicionar 1 participante ao departamento?'),
      findsOneWidget,
    );
    verifyNever(() => repository.addParticipant(any(), any()));
  });

  testWidgets('canceling confirmation does not call notifier', (tester) async {
    when(
      () => repository.addParticipant(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    await _pumpScreen(tester, members, repository: repository);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.addParticipant(any(), any()));
  });

  testWidgets('confirming calls notifier with selected membership ids', (
    tester,
  ) async {
    when(
      () => repository.addParticipant(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    await _pumpScreen(tester, members, repository: repository);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar').last);
    await tester.pumpAndSettle();

    final captured = verify(
      () => repository.addParticipant('dep-1', captureAny()),
    ).captured.cast<IntegrationRequestModel>().toList();
    expect(captured.map((request) => request.membershipId).toSet(), {
      'membership-1',
      'membership-2',
    });
  });

  testWidgets('total success shows success snackbar', (tester) async {
    when(
      () => repository.addParticipant(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    await _pumpScreen(tester, members, repository: repository);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar').last);
    await tester.pump();

    expect(find.text('Participantes adicionados com sucesso.'), findsOneWidget);
  });

  testWidgets('partial success shows failure counter', (tester) async {
    when(() => repository.addParticipant('dep-1', any())).thenAnswer((
      invocation,
    ) async {
      final request =
          invocation.positionalArguments[1] as IntegrationRequestModel;
      if (request.membershipId == 'membership-1') {
        return const Right(unit);
      }
      return const Left(ValidationFailure('Falha ao adicionar'));
    });
    await _pumpScreen(tester, members, repository: repository);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar').last);
    await tester.pump();

    expect(
      find.text(
        '1 participante adicionados. 1 participante não puderam ser adicionados.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('total failure keeps user on screen and shows error', (
    tester,
  ) async {
    when(
      () => repository.addParticipant(any(), any()),
    ).thenAnswer((_) async => const Left(ValidationFailure('Falha')));
    await _pumpScreen(tester, members, repository: repository);

    await tester.tap(find.text('Ana Mária'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar').last);
    await tester.pump();

    expect(
      find.text('Não foi possível adicionar os participantes selecionados.'),
      findsOneWidget,
    );
    expect(find.text('Pesquisar nome ou apelido...'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  List<UnitMemberEntity> members, {
  List<DepartmentParticipantEntity> participants = const [],
  DepartmentRepository? repository,
}) async {
  if (repository is _MockDepartmentRepository) {
    when(
      () => repository.getParticipants('dep-1'),
    ).thenAnswer((_) async => Right(participants));
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          departmentRepositoryProvider.overrideWithValue(repository),
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'active-membership',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
        rawUnitMembersProvider.overrideWith((ref, unitId) async => members),
        departmentParticipantsProvider.overrideWith(
          (ref, departmentId) async => participants,
        ),
      ],
      child: const MaterialApp(
        home: DepartmentParticipantsSelectionScreen(departmentId: 'dep-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
