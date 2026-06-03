import 'dart:async';

import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_detail_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/domain/entities/scale_assignment_person_entity.dart';
import 'package:client/features/scale/data/models/scale_item_request_model.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:client/features/scale/domain/entities/scale_item_entity.dart';
import 'package:client/features/scale/presentation/screens/department_scale_detail_screen.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarEventRepository extends Mock
    implements CalendarEventRepository {}

class _FakeScaleItemRequestModel extends Fake
    implements ScaleItemRequestModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeScaleItemRequestModel());
  });

  testWidgets('exibe título do evento', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Culto da manhã'), findsOneWidget);
  });

  testWidgets('exibe data e horário sem departamento', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Dom, 19 jul · 09h00'), findsOneWidget);
    expect(find.text('Dom, 19 jul · 09h00 · Louvor'), findsNothing);
  });

  testWidgets('exibe nome da formação', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Louvor completo'), findsOneWidget);
  });

  testWidgets('exibe pessoa alocada abaixo da função correta', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(
            roleId: 'role-1',
            roleName: 'Vocal',
            description: 'Voz principal',
            people: const [
              ScaleAssignmentPersonEntity(
                personId: 'person-1',
                displayName: 'Ana Silva',
                source: ScaleAssignmentPersonSource.participant,
              ),
            ],
          ),
          _assignment(
            roleId: 'role-2',
            roleName: 'Violão',
            description: 'Base harmônica',
          ),
        ],
      ),
    );

    final vocalSection = find.ancestor(
      of: find.text('Ana Silva'),
      matching: find.byType(Column),
    );

    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Voz principal'), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(
      find.descendant(of: vocalSection.first, matching: find.text('Vocal')),
      findsOneWidget,
    );
  });

  testWidgets('exibe Vaga aberta para função vazia', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(roleId: 'role-1', roleName: 'Vocal', people: const []),
        ],
      ),
    );

    expect(find.text('Vaga aberta'), findsOneWidget);
  });

  testWidgets('Vaga aberta aparece sem permissão de edição', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(roleId: 'role-1', roleName: 'Vocal', people: const []),
        ],
      ),
    );

    expect(find.text('Vaga aberta'), findsOneWidget);
    expect(find.text('Editar escala'), findsNothing);
    expect(find.text('Concluir'), findsNothing);
  });

  testWidgets('mantém funções visíveis com erro parcial de participantes', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        peopleLoadFailureMessage:
            'Não foi possível carregar todos os dados das pessoas.',
        assignments: [
          _assignment(
            roleId: 'role-1',
            roleName: 'Vocal',
            people: const [
              ScaleAssignmentPersonEntity(
                personId: 'person-404',
                displayName: 'Pessoa não encontrada',
                source: ScaleAssignmentPersonSource.notFound,
              ),
            ],
          ),
          _assignment(roleId: 'role-2', roleName: 'Violão'),
        ],
      ),
    );

    expect(
      find.text('Não foi possível carregar todos os dados das pessoas.'),
      findsOneWidget,
    );
    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Pessoa não encontrada'), findsOneWidget);
    expect(find.text('Violão'), findsOneWidget);
    expect(find.text('Vaga aberta'), findsOneWidget);
  });

  testWidgets('exibe duplicidade do mesmo nome na mesma função', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(
            roleId: 'role-1',
            roleName: 'Vocal',
            people: const [
              ScaleAssignmentPersonEntity(
                personId: 'person-1',
                displayName: 'Ana Silva',
                source: ScaleAssignmentPersonSource.participant,
              ),
              ScaleAssignmentPersonEntity(
                personId: 'person-1',
                displayName: 'Ana Silva',
                source: ScaleAssignmentPersonSource.participant,
              ),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Ana Silva'), findsOneWidget);
  });

  testWidgets('agrupa vagas repetidas do mesmo papel em uma secao', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(
            roleId: 'role-1',
            roleName: 'Vocal',
            capacity: 2,
            people: const [
              ScaleAssignmentPersonEntity(
                personId: 'person-1',
                displayName: 'Ana Silva',
                source: ScaleAssignmentPersonSource.participant,
              ),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Vaga aberta'), findsOneWidget);
  });

  testWidgets('mostra quantidade quando ha multiplas vagas abertas', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(
            roleId: 'role-1',
            roleName: 'Vocal',
            capacity: 2,
            people: const [],
          ),
        ],
      ),
    );

    expect(find.text('2 vagas abertas'), findsOneWidget);
    expect(find.text('Vaga aberta'), findsNothing);
  });

  testWidgets('confirma ausência de ações fora do escopo', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('+ Adicionar Pessoa'), findsNothing);
    expect(find.text('Adicionar pessoa'), findsNothing);
    expect(find.text('Adicionar Pessoa'), findsNothing);
    expect(find.text('Concluir'), findsNothing);
    expect(find.text('Editar escala'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
  });

  testWidgets('usuario sem permissao nao ve Adicionar pessoa', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Adicionar pessoa'), findsNothing);
  });

  testWidgets('usuario com canManageDept ve Adicionar pessoa', (tester) async {
    await _pumpScreen(tester, detail: _detail(), canManageScale: true);

    expect(find.text('Adicionar pessoa'), findsOneWidget);
  });

  testWidgets('usuario sem permissao nao ve acao de excluir escala', (
    tester,
  ) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.byTooltip('Ações da escala'), findsNothing);
  });

  testWidgets('usuario com canManageDept ve acao de excluir escala', (
    tester,
  ) async {
    await _pumpScreen(tester, detail: _detail(), canManageScale: true);

    await tester.tap(find.byTooltip('Ações da escala'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir escala'), findsOneWidget);
  });

  testWidgets('excluir escala confirma e mostra erro quando falha', (
    tester,
  ) async {
    final repository = _MockCalendarEventRepository();
    when(
      () => repository.deleteScale('scale-1'),
    ).thenAnswer((_) async => const Left(NetworkFailure('Falha simulada.')));

    await _pumpScreen(
      tester,
      detail: _detail(),
      canManageScale: true,
      repository: repository,
    );

    await tester.tap(find.byTooltip('Ações da escala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir escala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Falha simulada.'), findsOneWidget);
    verify(() => repository.deleteScale('scale-1')).called(1);
  });

  testWidgets('botao Adicionar pessoa fica desabilitado sem funcoes', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      canManageScale: true,
      detail: _detail(
        base: _baseDetail(
          lineup: const LineupEntity(
            id: 'lineup-1',
            name: 'Louvor completo',
            items: [],
          ),
        ),
        assignments: const [],
      ),
    );

    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Adicionar pessoa'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Concluir aparece apos selecionar pessoa localmente', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(roleId: 'role-1', roleName: 'Vocal', capacity: 2),
        ],
      ),
      canManageScale: true,
    );

    expect(find.text('Concluir'), findsNothing);

    await tester.tap(find.text('Adicionar pessoa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vocal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();

    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('Cancelar desfaz alteracoes locais sem salvar', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(roleId: 'role-1', roleName: 'Vocal', capacity: 2),
        ],
      ),
      canManageScale: true,
    );

    await tester.tap(find.text('Adicionar pessoa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vocal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Bruno Lima'), findsNothing);
    expect(find.text('Concluir'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
  });

  testWidgets('Vaga aberta abre seletor direto de pessoa para a funcao', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      canManageScale: true,
      detail: _detail(
        assignments: [
          _assignment(roleId: 'role-1', roleName: 'Vocal', people: const []),
        ],
      ),
    );

    await tester.tap(find.text('Vaga aberta'));
    await tester.pumpAndSettle();

    expect(find.text('Escolher pessoa'), findsOneWidget);
    expect(find.text('Escolher função'), findsNothing);

    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();

    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
  });

  testWidgets('Adicionar pessoa pede funcao antes de pessoa', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(roleId: 'role-1', roleName: 'Vocal', capacity: 2),
        ],
      ),
      canManageScale: true,
    );

    await tester.tap(find.text('Adicionar pessoa'));
    await tester.pumpAndSettle();

    expect(find.text('Escolher função'), findsOneWidget);
    expect(find.text('Vocal'), findsNWidgets(2));

    await tester.tap(find.text('Vocal').last);
    await tester.pumpAndSettle();

    expect(find.text('Escolher pessoa'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsOneWidget);
  });

  testWidgets(
    'selecionar pessoa duplicada no mesmo papel nao cria nova linha',
    (tester) async {
      await _pumpScreen(
        tester,
        detail: _detail(
          assignments: [
            _assignment(
              roleId: 'role-1',
              roleName: 'Vocal',
              capacity: 2,
              people: const [
                ScaleAssignmentPersonEntity(
                  personId: 'person-1',
                  displayName: 'Ana Silva',
                  source: ScaleAssignmentPersonSource.participant,
                ),
              ],
            ),
          ],
        ),
        canManageScale: true,
      );

      await tester.tap(find.text('Adicionar pessoa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vocal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Silva').last);
      await tester.pumpAndSettle();

      expect(find.text('Ana Silva'), findsOneWidget);
      expect(find.text('Concluir'), findsNothing);
    },
  );

  testWidgets('mesma pessoa pode ocupar papeis diferentes', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [
          _assignment(
            roleId: 'role-1',
            roleName: 'Vocal',
            people: const [
              ScaleAssignmentPersonEntity(
                personId: 'person-1',
                displayName: 'Ana Silva',
                source: ScaleAssignmentPersonSource.participant,
              ),
            ],
          ),
          _assignment(roleId: 'role-2', roleName: 'ViolÃ£o', people: const []),
        ],
      ),
      canManageScale: true,
    );

    await tester.tap(find.text('Adicionar pessoa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ViolÃ£o').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Silva').last);
    await tester.pumpAndSettle();

    expect(find.text('Ana Silva'), findsNWidgets(2));
    expect(find.text('Concluir'), findsOneWidget);
  });

  testWidgets('remove uma pessoa da funcao', (tester) async {
    await _pumpScreen(tester, detail: _detail(), canManageScale: true);

    expect(find.text('Ana Silva'), findsOneWidget);

    await tester.longPress(find.text('Ana Silva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover da escala'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Silva'), findsNothing);
    expect(find.text('Vaga aberta'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
  });

  testWidgets('remove pessoa e revela vaga quando havia capacidade maior', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      canManageScale: true,
      detail: _detail(
        assignments: [
          _assignment(
            roleId: 'role-1',
            roleName: 'Vocal',
            capacity: 2,
            people: const [
              ScaleAssignmentPersonEntity(
                personId: 'person-1',
                displayName: 'Ana Silva',
                scaleItemId: 'item-1',
                source: ScaleAssignmentPersonSource.participant,
              ),
              ScaleAssignmentPersonEntity(
                personId: 'person-2',
                displayName: 'Bruno Lima',
                scaleItemId: 'item-2',
                source: ScaleAssignmentPersonSource.participant,
              ),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsOneWidget);

    await tester.longPress(find.text('Ana Silva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover da escala'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Silva'), findsNothing);
    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Vaga aberta'), findsOneWidget);
  });

  testWidgets('mostra Vaga aberta depois de remover ultima pessoa', (
    tester,
  ) async {
    await _pumpScreen(tester, detail: _detail(), canManageScale: true);

    await tester.longPress(find.text('Ana Silva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover da escala'));
    await tester.pumpAndSettle();

    expect(find.text('Vaga aberta'), findsOneWidget);
  });

  testWidgets('usuario sem permissao nao ve acao de remover', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Ana Silva'), findsOneWidget);
    await tester.longPress(find.text('Ana Silva'));
    await tester.pumpAndSettle();
    expect(find.text('Remover da escala'), findsNothing);
  });

  testWidgets('toca em Concluir e chama salvamento', (tester) async {
    final repository = _MockCalendarEventRepository();
    when(
      () => repository.addScaleItem(
        scaleId: 'scale-1',
        request: any(named: 'request'),
      ),
    ).thenAnswer((_) async => const Right(_scaleItem));

    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [_assignment(roleId: 'role-1', roleName: 'Vocal')],
      ),
      canManageScale: true,
      repository: repository,
    );

    await tester.tap(find.text('Vaga aberta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    verify(
      () => repository.addScaleItem(
        scaleId: 'scale-1',
        request: any(
          named: 'request',
          that: isA<ScaleItemRequestModel>()
              .having((request) => request.roleId, 'roleId', 'role-1')
              .having((request) => request.personId, 'personId', 'person-2'),
        ),
      ),
    ).called(1);
  });

  testWidgets('mostra loading e desabilita acoes durante salvamento', (
    tester,
  ) async {
    final repository = _MockCalendarEventRepository();
    final completer = Completer<Either<Failure, ScaleItemEntity>>();
    when(
      () => repository.addScaleItem(
        scaleId: 'scale-1',
        request: any(named: 'request'),
      ),
    ).thenAnswer((_) => completer.future);

    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [_assignment(roleId: 'role-1', roleName: 'Vocal')],
      ),
      canManageScale: true,
      repository: repository,
    );

    await tester.tap(find.text('Vaga aberta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final completeButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(completeButton.onPressed, isNull);
    await tester.longPress(find.text('Bruno Lima'));
    await tester.pump();
    expect(find.text('Remover da escala'), findsNothing);

    completer.complete(const Right(_scaleItem));
    await tester.pumpAndSettle();
  });

  testWidgets('mostra Escala atualizada em sucesso e esconde Concluir', (
    tester,
  ) async {
    final repository = _MockCalendarEventRepository();
    when(
      () => repository.addScaleItem(
        scaleId: 'scale-1',
        request: any(named: 'request'),
      ),
    ).thenAnswer((_) async => const Right(_scaleItem));

    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [_assignment(roleId: 'role-1', roleName: 'Vocal')],
      ),
      canManageScale: true,
      repository: repository,
    );

    await tester.tap(find.text('Vaga aberta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Escala atualizada'), findsOneWidget);
    expect(find.text('Concluir'), findsNothing);
  });

  testWidgets('mostra erro em falha e preserva linhas locais', (tester) async {
    final repository = _MockCalendarEventRepository();
    when(
      () => repository.addScaleItem(
        scaleId: 'scale-1',
        request: any(named: 'request'),
      ),
    ).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao salvar escala.')),
    );

    await _pumpScreen(
      tester,
      detail: _detail(
        assignments: [_assignment(roleId: 'role-1', roleName: 'Vocal')],
      ),
      canManageScale: true,
      repository: repository,
    );

    await tester.tap(find.text('Vaga aberta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Lima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível atualizar a escala.'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
  });

  testWidgets('exibe formação sem itens', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        base: _baseDetail(
          lineup: const LineupEntity(
            id: 'lineup-1',
            name: 'Louvor completo',
            items: [],
          ),
        ),
        assignments: const [],
      ),
    );

    expect(find.text('Nenhuma função definida'), findsOneWidget);
  });

  testWidgets('exibe falha parcial da formação', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        base: _baseDetail(
          lineupState: DepartmentScaleLineupLoadState.failed,
          lineup: null,
        ),
        assignments: const [],
      ),
    );

    expect(
      find.text('Não foi possível carregar as funções da formação.'),
      findsOneWidget,
    );
    expect(find.text('Culto da manhã'), findsOneWidget);
  });

  testWidgets('exibe descrição discreta da função', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Voz principal'), findsOneWidget);

    final description = tester.widget<Text>(find.text('Voz principal'));
    expect(description.style?.color, AppColors.textSecondary);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required DepartmentScaleDetailEntity detail,
  bool canManageScale = false,
  List<DepartmentParticipantEntity>? participants,
  CalendarEventRepository? repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        departmentScaleAssignmentDetailProvider.overrideWith(
          (ref, request) => Stream.value(detail),
        ),
        if (repository != null)
          calendarEventRepositoryProvider.overrideWithValue(repository),
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://example.com/$imageId.png',
        ),
        sessionPermissionsProvider.overrideWith(
          (ref) async => _permissions(canManageScale: canManageScale),
        ),
        departmentParticipantsProvider.overrideWith(
          (ref, departmentId) async => participants ?? _participants(),
        ),
      ],
      child: const MaterialApp(
        home: DepartmentScaleDetailScreen(
          departmentId: 'dep-1',
          scaleId: 'scale-1',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _scaleItem = ScaleItemEntity(
  id: 'scale-item-1',
  scaleId: 'scale-1',
  roleId: 'role-1',
  personId: 'person-2',
);

List<DepartmentParticipantEntity> _participants() {
  return const [
    DepartmentParticipantEntity(
      personId: 'person-1',
      membershipId: 'membership-1',
      integrationType: IntegrationType.integrant,
      nickname: 'Ana Silva',
      username: 'ana.silva',
      affiliation: 'MEMBER',
      gender: 'FEMALE',
    ),
    DepartmentParticipantEntity(
      personId: 'person-2',
      membershipId: 'membership-2',
      integrationType: IntegrationType.integrant,
      nickname: 'Bruno Lima',
      username: 'bruno.lima',
      affiliation: 'MEMBER',
      gender: 'MALE',
    ),
  ];
}

SessionPermissions _permissions({required bool canManageScale}) {
  return SessionPermissions(
    isAuthenticated: true,
    affiliation: Affiliation.member,
    activeUnitId: 'unit-1',
    hasMembership: true,
    integrations: canManageScale
        ? const [
            IntegrationEntity(
              id: 'integration-1',
              membershipId: 'membership-1',
              departmentId: 'dep-1',
              departmentType: 'MINISTRY',
              integrationType: IntegrationType.assistant,
            ),
          ]
        : const [],
    isUnitAdmin: false,
  );
}

DepartmentScaleDetailEntity _detail({
  DepartmentScaleWithLineupEntity? base,
  List<ScaleRoleAssignmentsEntity>? assignments,
  String? peopleLoadFailureMessage,
}) {
  final resolvedAssignments =
      assignments ??
      [
        _assignment(
          roleId: 'role-1',
          roleName: 'Vocal',
          description: 'Voz principal',
          people: const [
            ScaleAssignmentPersonEntity(
              personId: 'person-1',
              displayName: 'Ana Silva',
              source: ScaleAssignmentPersonSource.participant,
            ),
          ],
        ),
      ];

  return DepartmentScaleDetailEntity(
    base: base ?? _baseDetail(items: resolvedAssignments.map((a) => a.item)),
    roleAssignments: resolvedAssignments,
    peopleLoadFailureMessage: peopleLoadFailureMessage,
  );
}

DepartmentScaleWithLineupEntity _baseDetail({
  DepartmentScaleLineupLoadState lineupState =
      DepartmentScaleLineupLoadState.loaded,
  LineupEntity? lineup,
  Iterable<LineupItemEntity>? items,
}) {
  return DepartmentScaleWithLineupEntity(
    scale: DepartmentCalendarEventScaleEntity(
      scale: const CalendarEventScaleEntity(
        id: 'scale-1',
        lineupId: 'lineup-1',
        type: CalendarEventScaleType.owner,
        calendarEventId: 'event-1',
      ),
      calendarEvent: CalendarEventEntity(
        id: 'event-1',
        title: 'Culto da manhã',
        startDateTime: DateTime(2026, 7, 19, 9),
        endDateTime: DateTime(2026, 7, 19, 11),
        type: CalendarEventType.department,
        departmentId: 'dep-1',
      ),
    ),
    lineupState: lineupState,
    lineup:
        lineup ??
        LineupEntity(
          id: 'lineup-1',
          name: 'Louvor completo',
          items: items?.toList() ?? const [],
        ),
  );
}

ScaleRoleAssignmentsEntity _assignment({
  required String roleId,
  required String roleName,
  String description = '',
  int capacity = 1,
  List<ScaleAssignmentPersonEntity> people = const [],
}) {
  return ScaleRoleAssignmentsEntity(
    item: LineupItemEntity(
      id: 'item-$roleId',
      lineupId: 'lineup-1',
      roleId: roleId,
      description: description,
      role: RoleEntity(id: roleId, name: roleName, slug: roleId),
    ),
    people: people,
    capacity: capacity,
  );
}
