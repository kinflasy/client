import 'package:client/core/errors/failure.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/scale/data/models/scale_item_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/scale_item_entity.dart';
import 'package:client/features/calendar/domain/entities/event_collaboration_entity.dart';
import 'package:client/features/calendar/domain/entities/person_birthday_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/calendar/sub_features/create_event/presentation/screens/create_event_screen.dart';
import 'package:client/features/calendar/sub_features/create_event/providers/event_image_picker_provider.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  Widget buildApp({
    _CapturingCalendarEventRepository? repository,
    String? eventId,
    CalendarEventEntity? event,
    EventImagePicker? picker,
    String? lockedDepartmentId,
    String? duplicateFromEventId,
  }) {
    return ProviderScope(
      overrides: [
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        departmentsProvider('unit-1').overrideWith(
          (ref) async => const [
            DepartmentEntity(id: 'dep-1', name: 'Louvor'),
            DepartmentEntity(id: 'dep-2', name: 'Recepcao'),
          ],
        ),
        if (event != null)
          calendarEventDetailProvider(
            event.id,
          ).overrideWith((ref) async => event),
        calendarEventCollaboratorsProvider.overrideWith(
          (ref, eventId) async => repository?.collaborators ?? const [],
        ),
        departmentDetailProvider.overrideWith(
          (ref, departmentId) async => DepartmentDetailEntity(
            id: departmentId,
            name: switch (departmentId) {
              'dep-1' => 'Louvor',
              'dep-2' => 'Recepcao',
              'dep-3' => 'Comunicação',
              _ => 'Nome resolvido',
            },
          ),
        ),
        if (repository != null)
          calendarEventRepositoryProvider.overrideWithValue(repository),
        if (picker != null) eventImagePickerProvider.overrideWithValue(picker),
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://example.com/$imageId.png',
        ),
      ],
      child: MaterialApp(
        home: CreateEventScreen(
          eventId: eventId,
          lockedDepartmentId: lockedDepartmentId,
          duplicateFromEventId: duplicateFromEventId,
        ),
      ),
    );
  }

  testWidgets('valida campos obrigatórios', (tester) async {
    await _pumpApp(tester, buildApp());

    expect(find.text('Organizado por *'), findsOneWidget);
    expect(find.text('Evento de *'), findsNothing);

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('Campo obrigatório'), findsNWidgets(5));
    expect(
      find.text('Adicione pelo menos uma regra de visibilidade.'),
      findsNothing,
    );
  });

  testWidgets('valida fim anterior ao início', (tester) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'Ensaio geral');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '20:00');
    await tester.enterText(_field('end-date-field'), '10/05/2026');
    await tester.enterText(_field('end-time-field'), '18:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('O fim deve ser posterior ao início.'), findsOneWidget);
  });

  testWidgets('autopreenche data e hora de fim a partir do início', (
    tester,
  ) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.pump();

    expect(_fieldText(tester, 'end-date-field'), '10/05/2026');
    expect(_fieldText(tester, 'end-time-field'), '20:00');
  });

  testWidgets('autopreenchimento ajusta data de fim na virada de dia', (
    tester,
  ) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '23:30');
    await tester.pump();

    expect(_fieldText(tester, 'end-date-field'), '11/05/2026');
    expect(_fieldText(tester, 'end-time-field'), '01:30');
  });

  testWidgets('autopreenchimento não sobrescreve fim manual', (tester) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(_field('end-date-field'), '12/05/2026');
    await tester.enterText(_field('end-time-field'), '21:00');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.pump();

    expect(_fieldText(tester, 'end-date-field'), '12/05/2026');
    expect(_fieldText(tester, 'end-time-field'), '21:00');
  });

  testWidgets('salvar sem regra específica envia USER *', (tester) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(tester, buildApp(repository: repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ensaio geral');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.enterText(_field('end-date-field'), '10/05/2026');
    await tester.enterText(_field('end-time-field'), '20:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.createdUnitEventRequest, isNotNull);
    expect(repository.createdUnitEventRequest!.visibilityRules, const [
      VisibilityRuleEntity.user(userId: '*'),
    ]);
    expect(
      find.text('Adicione pelo menos uma regra de visibilidade.'),
      findsNothing,
    );
  });

  testWidgets('permite criar evento com data futura digitada', (tester) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(tester, buildApp(repository: repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'Retiro');
    await tester.enterText(_field('start-date-field'), '15/08/2027');
    await tester.enterText(_field('start-time-field'), '09:00');
    await tester.enterText(_field('end-date-field'), '15/08/2027');
    await tester.enterText(_field('end-time-field'), '18:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.createdUnitEventRequest, isNotNull);
    expect(
      repository.createdUnitEventRequest!.startDateTime,
      DateTime(2027, 8, 15, 9),
    );
    expect(
      repository.createdUnitEventRequest!.endDateTime,
      DateTime(2027, 8, 15, 18),
    );
    expect(find.text('Data inválida'), findsNothing);
  });

  testWidgets('modo edição preenche formulário com dados existentes', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      buildApp(
        eventId: 'event-1',
        event: _event(cardImageId: 'image-1'),
      ),
    );

    expect(find.text('Editar evento'), findsOneWidget);
    expect(_fieldTextAt(tester, 0), 'Culto especial');
    expect(_fieldTextAt(tester, 1), 'Celebração com toda a unidade.');
    expect(_fieldText(tester, 'start-date-field'), '10/05/2026');
    expect(_fieldText(tester, 'start-time-field'), '18:00');
    expect(_fieldText(tester, 'end-date-field'), '10/05/2026');
    expect(_fieldText(tester, 'end-time-field'), '20:00');
    expect(find.text('Salvar alterações'), findsOneWidget);
    expect(find.text('Imagem do evento'), findsOneWidget);
    expect(find.text('Trocar imagem'), findsOneWidget);
  });

  testWidgets('modo edição valida fim posterior ao início', (tester) async {
    await _pumpApp(tester, buildApp(eventId: 'event-1', event: _event()));

    await tester.enterText(_field('end-time-field'), '17:00');
    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('O fim deve ser posterior ao início.'), findsOneWidget);
  });

  testWidgets('modo edição envia update com dados alterados', (tester) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(
      tester,
      buildApp(repository: repository, eventId: 'event-1', event: _event()),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Culto atualizado',
    );
    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedEventId, 'event-1');
    expect(repository.updatedEventRequest?.title, 'Culto atualizado');
  });

  testWidgets('modo edição permite salvar nova data futura', (tester) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(
      tester,
      buildApp(repository: repository, eventId: 'event-1', event: _event()),
    );

    await tester.enterText(_field('start-date-field'), '20/09/2027');
    await tester.enterText(_field('start-time-field'), '10:00');
    await tester.enterText(_field('end-date-field'), '20/09/2027');
    await tester.enterText(_field('end-time-field'), '12:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedEventId, 'event-1');
    expect(
      repository.updatedEventRequest?.startDateTime,
      DateTime(2027, 9, 20, 10),
    );
    expect(
      repository.updatedEventRequest?.endDateTime,
      DateTime(2027, 9, 20, 12),
    );
    expect(find.text('Data inválida'), findsNothing);
  });

  testWidgets('modo edição atualiza imagem do evento', (tester) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(
      tester,
      buildApp(
        repository: repository,
        eventId: 'event-1',
        event: _event(cardImageId: 'image-1'),
        picker: const _FakeEventImagePicker(
          PickedEventImage(
            path: '/tmp/card.png',
            name: 'card.png',
            sizeInBytes: 1024,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trocar imagem'));
    await tester.pumpAndSettle();

    expect(repository.updatedCardImageEventId, 'event-1');
    expect(repository.updatedCardImagePath, '/tmp/card.png');
    expect(find.text('Imagem do evento atualizada.'), findsOneWidget);
  });

  testWidgets('modo edição remove imagem do evento após confirmação', (
    tester,
  ) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(
      tester,
      buildApp(
        repository: repository,
        eventId: 'event-1',
        event: _event(cardImageId: 'image-1'),
      ),
    );

    await tester.tap(find.text('Remover imagem'));
    await tester.pumpAndSettle();

    expect(repository.deletedCardImageEventId, isNull);
    expect(
      find.text('Tem certeza que deseja remover a imagem do evento?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(repository.deletedCardImageEventId, 'event-1');
    expect(find.text('Imagem do evento removida.'), findsOneWidget);
  });

  testWidgets('modo duplicação preenche dados copiáveis do evento original', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      buildApp(duplicateFromEventId: 'event-1', event: _event()),
    );

    expect(find.text('Duplicar evento'), findsOneWidget);
    expect(_fieldTextAt(tester, 0), 'Culto especial');
    expect(_fieldTextAt(tester, 1), 'Celebração com toda a unidade.');
    expect(_fieldText(tester, 'start-date-field'), isEmpty);
    expect(_fieldText(tester, 'end-date-field'), isEmpty);
    expect(_fieldText(tester, 'start-time-field'), '18:00');
    expect(_fieldText(tester, 'end-time-field'), '20:00');
    expect(find.text('Salvar evento'), findsOneWidget);
  });

  testWidgets('modo duplicação não exibe imagem original como selecionada', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      buildApp(
        duplicateFromEventId: 'event-1',
        event: _event(cardImageId: 'image-1'),
      ),
    );

    expect(find.text('Selecionar imagem'), findsOneWidget);
    expect(find.text('Trocar imagem'), findsNothing);
    expect(find.byKey(const Key('event-image-network')), findsNothing);
  });

  testWidgets('modo duplicação exige datas mesmo com horários copiados', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      buildApp(duplicateFromEventId: 'event-1', event: _event()),
    );

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('Campo obrigatório'), findsNWidgets(2));
  });

  testWidgets('modo duplicação cria novo evento de unidade', (tester) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(
      tester,
      buildApp(
        repository: repository,
        duplicateFromEventId: 'event-1',
        event: _event(),
      ),
    );

    await tester.enterText(_field('start-date-field'), '12/05/2026');
    await tester.enterText(_field('end-date-field'), '12/05/2026');
    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.createdUnitEventRequest, isNotNull);
    expect(repository.updatedEventId, isNull);
    expect(repository.createdUnitEventRequest!.title, 'Culto especial');
    expect(
      repository.createdUnitEventRequest!.startDateTime,
      DateTime(2026, 5, 12, 18),
    );
    expect(
      repository.createdUnitEventRequest!.endDateTime,
      DateTime(2026, 5, 12, 20),
    );
  });

  testWidgets('modo duplicação cria evento no departamento original', (
    tester,
  ) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(
      tester,
      buildApp(
        repository: repository,
        duplicateFromEventId: 'event-1',
        event: _event(
          type: CalendarEventType.department,
          departmentId: 'dep-1',
        ),
      ),
    );

    await tester.enterText(_field('start-date-field'), '12/05/2026');
    await tester.enterText(_field('end-date-field'), '12/05/2026');
    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.createdDepartmentId, 'dep-1');
    expect(repository.createdDepartmentEventRequest, isNotNull);
    expect(repository.createdUnitEventRequest, isNull);
    expect(repository.updatedEventId, isNull);
  });

  testWidgets('modo departamento travado cria evento para o departamento', (
    tester,
  ) async {
    final repository = _CapturingCalendarEventRepository();
    await _pumpApp(
      tester,
      buildApp(repository: repository, lockedDepartmentId: 'dep-1'),
    );

    expect(find.text('Organizado por *'), findsNothing);
    expect(find.text('Departamento *'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ensaio geral');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.enterText(_field('end-date-field'), '10/05/2026');
    await tester.enterText(_field('end-time-field'), '20:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.createdDepartmentId, 'dep-1');
    expect(repository.createdDepartmentEventRequest, isNotNull);
    expect(repository.createdUnitEventRequest, isNull);
  });

  testWidgets('cria evento e adiciona colaboradores selecionados', (
    tester,
  ) async {
    final repository = _CapturingCalendarEventRepository()
      ..createdEventResult = _event();
    await _pumpApp(tester, buildApp(repository: repository));

    await tester.tap(find.byKey(const Key('add-event-collaborator-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-add-collaborator-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ensaio geral');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.enterText(_field('end-date-field'), '10/05/2026');
    await tester.enterText(_field('end-time-field'), '20:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.createdUnitEventRequest, isNotNull);
    expect(repository.collaboratorDepartmentIds, ['dep-1']);
  });

  testWidgets('modo edição remove colaborador desmarcado ao salvar', (
    tester,
  ) async {
    final repository = _CapturingCalendarEventRepository()
      ..updatedEventResult = _event()
      ..collaborators = const [
        EventCollaborationEntity(
          id: 'collab-1',
          calendarEventId: 'event-1',
          departmentId: 'dep-1',
          department: DepartmentEntity(id: 'dep-1', name: 'Louvor'),
        ),
      ];
    await _pumpApp(
      tester,
      buildApp(repository: repository, eventId: 'event-1', event: _event()),
    );

    await tester.tap(find.byKey(const Key('remove-collaborator-dep-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedEventId, 'event-1');
    expect(repository.removedCollaboratorDepartmentIds, ['dep-1']);
  });

  testWidgets('modo duplicação copia colaboradores para o novo evento', (
    tester,
  ) async {
    final repository = _CapturingCalendarEventRepository()
      ..createdEventResult = _event(title: 'Culto copiado')
      ..collaborators = const [
        EventCollaborationEntity(
          id: 'collab-2',
          calendarEventId: 'event-1',
          departmentId: 'dep-2',
          department: DepartmentEntity(id: 'dep-2', name: 'Recepcao'),
        ),
      ];
    await _pumpApp(
      tester,
      buildApp(
        repository: repository,
        duplicateFromEventId: 'event-1',
        event: _event(),
      ),
    );

    expect(find.text('Recepcao'), findsOneWidget);

    await tester.enterText(_field('start-date-field'), '12/05/2026');
    await tester.enterText(_field('end-date-field'), '12/05/2026');
    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(repository.createdUnitEventRequest, isNotNull);
    expect(repository.collaboratorDepartmentIds, ['dep-2']);
  });

  testWidgets('evento departamental não permite colaborar com dono', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      buildApp(
        eventId: 'event-1',
        event: _event(
          type: CalendarEventType.department,
          departmentId: 'dep-1',
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('add-event-collaborator-button')));
    await tester.pumpAndSettle();

    expect(find.text('Recepcao'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-add-collaborator-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('remove-collaborator-dep-2')), findsOneWidget);
    expect(find.byKey(const Key('remove-collaborator-dep-1')), findsNothing);
  });

  testWidgets('colaborador carregado sem detalhe usa lista de departamentos', (
    tester,
  ) async {
    final repository = _CapturingCalendarEventRepository()
      ..collaborators = const [
        EventCollaborationEntity(
          id: 'collab-2',
          calendarEventId: 'event-1',
          departmentId: 'dep-2',
        ),
      ];
    await _pumpApp(
      tester,
      buildApp(repository: repository, eventId: 'event-1', event: _event()),
    );

    expect(find.text('Recepcao'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('event-collaborators-section')),
        matching: find.text('Departamento'),
      ),
      findsNothing,
    );
  });

  testWidgets('colaborador fora da lista resolve nome pelo detalhe', (
    tester,
  ) async {
    final repository = _CapturingCalendarEventRepository()
      ..collaborators = const [
        EventCollaborationEntity(
          id: 'collab-3',
          calendarEventId: 'event-1',
          departmentId: 'dep-3',
        ),
      ];
    await _pumpApp(
      tester,
      buildApp(repository: repository, eventId: 'event-1', event: _event()),
    );

    expect(find.text('Comunicação'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('event-collaborators-section')),
        matching: find.text('Departamento'),
      ),
      findsNothing,
    );
  });
}

Future<void> _pumpApp(WidgetTester tester, Widget app) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Finder _field(String key) {
  return find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextFormField),
  );
}

String _fieldText(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(_field(key)).controller!.text;
}

String _fieldTextAt(WidgetTester tester, int index) {
  return tester
      .widget<TextFormField>(find.byType(TextFormField).at(index))
      .controller!
      .text;
}

CurrentChurchProfileEntity _profile() {
  return const CurrentChurchProfileEntity(
    membership: MembershipEntity(
      id: 'membership-1',
      unitId: 'unit-1',
      affiliation: 'UNIT_ADMIN',
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

class _CapturingCalendarEventRepository implements CalendarEventRepository {
  CalendarEventRequestModel? createdUnitEventRequest;
  String? createdDepartmentId;
  CalendarEventRequestModel? createdDepartmentEventRequest;
  CalendarEventEntity? createdEventResult;
  String? updatedEventId;
  CalendarEventRequestModel? updatedEventRequest;
  CalendarEventEntity? updatedEventResult;
  String? updatedCardImageEventId;
  String? updatedCardImagePath;
  String? deletedCardImageEventId;
  final collaboratorDepartmentIds = <String>[];
  final removedCollaboratorDepartmentIds = <String>[];
  List<EventCollaborationEntity> collaborators = const [];

  @override
  Future<Either<Failure, List<CalendarEventEntity>>> getVisibleEvents(
    DateTime start,
    DateTime end,
  ) async {
    return const Left(ServerFailure('NÃ£o implementado no teste.'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> createUnitEvent(
    String unitId,
    CalendarEventRequestModel request,
  ) async {
    createdUnitEventRequest = request;
    if (createdEventResult != null) return Right(createdEventResult!);
    return const Left(ServerFailure('Falha simulada.'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> createDepartmentEvent(
    String departmentId,
    CalendarEventRequestModel request,
  ) async {
    createdDepartmentId = departmentId;
    createdDepartmentEventRequest = request;
    if (createdEventResult != null) return Right(createdEventResult!);
    return const Left(ServerFailure('Falha simulada.'));
  }

  @override
  Future<Either<Failure, EventCollaborationEntity>> addCollaborator(
    String eventId,
    String departmentId,
  ) async {
    collaboratorDepartmentIds.add(departmentId);
    return Right(
      EventCollaborationEntity(
        id: 'collaboration-$departmentId',
        calendarEventId: eventId,
        departmentId: departmentId,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> deleteCardImage(String eventId) async {
    deletedCardImageEventId = eventId;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String eventId) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> getEventById(
    String eventId,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<EventCollaborationEntity>>> getCollaborators(
    String eventId,
  ) async {
    return Right(collaborators);
  }

  @override
  Future<Either<Failure, List<CalendarEventScaleEntity>>> getEventScales(
    String eventId,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, CalendarEventScaleEntity>> getScaleById(
    String scaleId,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, void>> deleteScale(String scaleId) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<ScaleItemEntity>>> getScaleItems(
    String scaleId,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<DepartmentCalendarEventScaleEntity>>>
  getDepartmentScales(String departmentId, DateTime start, DateTime end) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<CalendarEventEntity>>> getDepartmentEvents(
    String departmentId,
    DateTime start,
    DateTime end,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<CalendarEventEntity>>>
  getDepartmentEventsWithCollabs(
    String departmentId,
    DateTime start,
    DateTime end,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<CalendarEventEntity>>> getUnitEvents(
    String unitId,
    DateTime start,
    DateTime end,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, List<PersonBirthdayEntity>>> getUnitBirthdays(
    DateTime start,
    DateTime end,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, void>> removeCollaborator(
    String eventId,
    String departmentId,
  ) async {
    removedCollaboratorDepartmentIds.add(departmentId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, CalendarEventScaleEntity>> createEventScale(
    String eventId,
    CalendarEventScaleRequestModel request,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, CalendarEventScaleEntity>>
  createCollaboratorEventScale(
    String eventId,
    String departmentId,
    CalendarEventScaleRequestModel request,
  ) async {
    return const Left(ServerFailure('Não implementado no teste.'));
  }

  @override
  Future<Either<Failure, ScaleItemEntity>> addScaleItem({
    required String scaleId,
    required ScaleItemRequestModel request,
  }) async {
    return const Left(ServerFailure('NÃ£o implementado no teste.'));
  }

  @override
  Future<Either<Failure, void>> removeScaleItem({
    required String scaleId,
    required ScaleItemRequestModel request,
  }) async {
    return const Left(ServerFailure('NÃ£o implementado no teste.'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> updateCardImage(
    String eventId,
    String filePath,
  ) async {
    updatedCardImageEventId = eventId;
    updatedCardImagePath = filePath;
    return Right(_event(cardImageId: 'image-2'));
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> updateEvent(
    String eventId,
    CalendarEventRequestModel request,
  ) async {
    updatedEventId = eventId;
    updatedEventRequest = request;
    if (updatedEventResult != null) return Right(updatedEventResult!);
    return const Left(ServerFailure('Não implementado no teste.'));
  }
}

class _FakeEventImagePicker implements EventImagePicker {
  const _FakeEventImagePicker(this.image);

  final PickedEventImage? image;

  @override
  Future<PickedEventImage?> pickImage() async => image;
}

CalendarEventEntity _event({
  String title = 'Culto especial',
  String? cardImageId,
  CalendarEventType type = CalendarEventType.unit,
  String? departmentId,
}) {
  return CalendarEventEntity(
    id: 'event-1',
    title: title,
    description: 'Celebração com toda a unidade.',
    startDateTime: DateTime(2026, 5, 10, 18),
    endDateTime: DateTime(2026, 5, 10, 20),
    type: type,
    unitId: type == CalendarEventType.unit ? 'unit-1' : null,
    departmentId: type == CalendarEventType.department ? departmentId : null,
    cardImageId: cardImageId,
    visibilityRules: const [VisibilityRuleEntity.user(userId: '*')],
  );
}
