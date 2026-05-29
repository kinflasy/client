import 'dart:async';

import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/event_collaboration_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/presentation/widgets/event_detail_bottom_sheet.dart';
import 'package:client/features/calendar/presentation/widgets/event_image.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarEventRepository extends Mock
    implements CalendarEventRepository {}

void main() {
  testWidgets('renderiza loading enquanto carrega o detalhe', (tester) async {
    final completer = Completer<CalendarEventEntity>();
    addTearDown(() {
      if (!completer.isCompleted) completer.complete(_event());
    });

    await tester.pumpWidget(_build(loadDetail: (_) => completer.future));

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Carregando detalhes do evento...'), findsOneWidget);
  });

  testWidgets('renderiza erro quando detalhe falha', (tester) async {
    await tester.pumpWidget(
      _build(loadDetail: (_) => Future.error(Exception('falha'))),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os detalhes do evento.'),
      findsOneWidget,
    );
    expect(find.text('Tente novamente em instantes.'), findsOneWidget);
  });

  testWidgets('renderiza detalhe do evento', (tester) async {
    await tester.pumpWidget(_build(loadDetail: (_) async => _event()));

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Culto de Celebração'), findsOneWidget);
    expect(find.text('10 mai 18:00 - 10 mai 20:00'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('Encontro aberto para toda a unidade.'), findsOneWidget);
  });

  testWidgets('renderiza imagem no topo do detalhe quando existe cardImageId', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(cardImageId: 'image-1'),
        resolveImageUrl: (_) async => 'https://example.com/event.png',
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.byType(EventImage), findsOneWidget);
    expect(find.byKey(const Key('event-image-network')), findsOneWidget);
  });

  testWidgets('exige confirmação antes de excluir evento', (tester) async {
    final repository = _MockCalendarEventRepository();
    when(
      () => repository.deleteEvent('event-1'),
    ).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(),
        canAdmin: true,
        repository: repository,
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir evento'), findsWidgets);
    expect(
      find.text('Tem certeza que deseja excluir este evento?'),
      findsOneWidget,
    );
    verifyNever(() => repository.deleteEvent('event-1'));

    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteEvent('event-1')).called(1);
    expect(find.text('Evento excluído.'), findsOneWidget);
  });

  testWidgets('não mostra ações de imagem no detalhe', (tester) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(cardImageId: 'image-1'),
        canAdmin: true,
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Duplicar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
    expect(find.text('Trocar imagem'), findsNothing);
    expect(find.text('Adicionar imagem'), findsNothing);
    expect(find.text('Remover imagem'), findsNothing);
  });
  testWidgets('mostra ações para líder do departamento do evento', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async =>
            _event(type: CalendarEventType.department, departmentId: 'dep-1'),
        departmentRole: IntegrationType.leader,
        roleDepartmentId: 'dep-1',
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Duplicar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
  });

  testWidgets('mostra ações para auxiliar do departamento do evento', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async =>
            _event(type: CalendarEventType.department, departmentId: 'dep-1'),
        departmentRole: IntegrationType.assistant,
        roleDepartmentId: 'dep-1',
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Duplicar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
  });

  testWidgets('não mostra ações para líder de outro departamento', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async =>
            _event(type: CalendarEventType.department, departmentId: 'dep-2'),
        departmentRole: IntegrationType.leader,
        roleDepartmentId: 'dep-1',
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsNothing);
    expect(find.text('Duplicar'), findsNothing);
    expect(find.text('Excluir'), findsNothing);
  });

  testWidgets('admin da unidade vê colaboradores abaixo da descrição', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(),
        canAdmin: true,
        loadCollaborators: (_) async => const [
          EventCollaborationEntity(
            id: 'collab-1',
            calendarEventId: 'event-1',
            departmentId: 'dep-1',
            department: DepartmentEntity(id: 'dep-1', name: 'Louvor'),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Departamentos colaboradores'), findsOneWidget);
    expect(find.text('Louvor'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('líder do departamento dono vê colaboradores', (tester) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async =>
            _event(type: CalendarEventType.department, departmentId: 'dep-1'),
        departmentRole: IntegrationType.leader,
        roleDepartmentId: 'dep-1',
        loadCollaborators: (_) async => const [
          EventCollaborationEntity(
            id: 'collab-2',
            calendarEventId: 'event-1',
            departmentId: 'dep-2',
            department: DepartmentEntity(id: 'dep-2', name: 'Recepção'),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Departamentos colaboradores'), findsOneWidget);
    expect(find.text('Recepção'), findsOneWidget);
  });

  testWidgets('usuário sem permissão não carrega nem vê colaboradores', (
    tester,
  ) async {
    var loadCount = 0;
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(),
        loadCollaborators: (_) async {
          loadCount++;
          return const [
            EventCollaborationEntity(
              id: 'collab-1',
              calendarEventId: 'event-1',
              departmentId: 'dep-1',
              department: DepartmentEntity(id: 'dep-1', name: 'Louvor'),
            ),
          ];
        },
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(loadCount, 0);
    expect(find.text('Departamentos colaboradores'), findsNothing);
    expect(find.text('Louvor'), findsNothing);
  });

  testWidgets('sem colaboradores não mostra a seção', (tester) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(),
        canAdmin: true,
        loadCollaborators: (_) async => const [],
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Departamentos colaboradores'), findsNothing);
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('falha de colaboradores mostra erro discreto e mantém ações', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(),
        canAdmin: true,
        loadCollaborators: (_) => Future.error(Exception('falha')),
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os colaboradores.'),
      findsOneWidget,
    );
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Duplicar'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
  });

  testWidgets('colaborador sem departamento detalhado usa nome do detalhe', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(),
        canAdmin: true,
        loadCollaborators: (_) async => const [
          EventCollaborationEntity(
            id: 'collab-1',
            calendarEventId: 'event-1',
            departmentId: 'dep-1',
          ),
        ],
        loadDepartmentDetail: (_) async =>
            const DepartmentDetailEntity(id: 'dep-1', name: 'Comunicação'),
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(find.text('Comunicação'), findsOneWidget);
    expect(find.text('Departamento'), findsNothing);
  });

  testWidgets('erro ao buscar departamento mostra mensagem por colaborador', (
    tester,
  ) async {
    await tester.pumpWidget(
      _build(
        loadDetail: (_) async => _event(),
        canAdmin: true,
        loadCollaborators: (_) async => const [
          EventCollaborationEntity(
            id: 'collab-1',
            calendarEventId: 'event-1',
            departmentId: 'dep-1',
          ),
        ],
        loadDepartmentDetail: (_) => Future.error(Exception('falha')),
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar o departamento'),
      findsOneWidget,
    );
    expect(find.text('Departamento'), findsNothing);
  });
}

Widget _build({
  required Future<CalendarEventEntity> Function(String eventId) loadDetail,
  Future<List<EventCollaborationEntity>> Function(String eventId)?
  loadCollaborators,
  Future<DepartmentDetailEntity> Function(String departmentId)?
  loadDepartmentDetail,
  Future<String> Function(String imageId)? resolveImageUrl,
  bool canAdmin = false,
  IntegrationType? departmentRole,
  String roleDepartmentId = 'dep-1',
  CalendarEventRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      calendarEventDetailProvider.overrideWith(
        (ref, eventId) => loadDetail(eventId),
      ),
      calendarEventCollaboratorsProvider.overrideWith(
        (ref, eventId) => loadCollaborators?.call(eventId) ?? Future.value([]),
      ),
      departmentDetailProvider.overrideWith(
        (ref, departmentId) =>
            loadDepartmentDetail?.call(departmentId) ??
            Future.value(
              DepartmentDetailEntity(id: departmentId, name: 'Departamento'),
            ),
      ),
      mediaImageUrlProvider.overrideWith(
        (ref, imageId) async =>
            resolveImageUrl?.call(imageId) ??
            Future.value('https://example.com/event.png'),
      ),
      sessionPermissionsProvider.overrideWith(
        (ref) async => _permissions(
          isUnitAdmin: canAdmin,
          departmentRole: departmentRole,
          roleDepartmentId: roleDepartmentId,
        ),
      ),
      if (repository != null)
        calendarEventRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  showEventDetailBottomSheet(context, eventId: 'event-1'),
              child: const Text('Abrir detalhe'),
            ),
          ),
        ),
      ),
    ),
  );
}

SessionPermissions _permissions({
  required bool isUnitAdmin,
  IntegrationType? departmentRole,
  String roleDepartmentId = 'dep-1',
}) {
  return SessionPermissions(
    isAuthenticated: true,
    affiliation: Affiliation.member,
    activeUnitId: 'unit-1',
    hasMembership: true,
    integrations: departmentRole == null
        ? const []
        : [
            IntegrationEntity(
              id: 'integration-1',
              membershipId: 'membership-1',
              departmentId: roleDepartmentId,
              departmentType: 'MINISTRY',
              integrationType: departmentRole,
            ),
          ],
    isUnitAdmin: isUnitAdmin,
  );
}

CalendarEventEntity _event({
  String? cardImageId,
  CalendarEventType type = CalendarEventType.unit,
  String? departmentId,
}) {
  return CalendarEventEntity(
    id: 'event-1',
    title: 'Culto de Celebração',
    description: 'Encontro aberto para toda a unidade.',
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: type,
    unitId: type == CalendarEventType.unit ? 'unit-1' : null,
    departmentId: type == CalendarEventType.department ? departmentId : null,
    cardImageId: cardImageId,
  );
}
