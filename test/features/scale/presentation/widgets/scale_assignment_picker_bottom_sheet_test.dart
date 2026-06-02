import 'dart:async';

import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/scale/presentation/widgets/scale_assignment_picker_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lista funcoes da formacao', (tester) async {
    await _pumpPicker(tester);

    expect(find.text('Escolher função'), findsOneWidget);
    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Violão'), findsOneWidget);
  });

  testWidgets('filtra participantes por busca', (tester) async {
    await _pumpPicker(
      tester,
      initialRole: _role(roleId: 'role-1', name: 'Vocal'),
    );

    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bru');
    await tester.pump();

    expect(find.text('Ana Silva'), findsNothing);
    expect(find.text('Bruno Lima'), findsOneWidget);
  });

  testWidgets('mostra participantes direto quando recebe funcao inicial', (
    tester,
  ) async {
    await _pumpPicker(
      tester,
      initialRole: _role(roleId: 'role-1', name: 'Vocal'),
    );

    expect(find.text('Escolher pessoa'), findsOneWidget);
    expect(find.text('Escolher função'), findsNothing);
    expect(find.text('Ana Silva'), findsOneWidget);
  });

  testWidgets('mostra estado vazio de participantes', (tester) async {
    await _pumpPicker(
      tester,
      initialRole: _role(roleId: 'role-1', name: 'Vocal'),
      participants: const [],
    );

    expect(find.text('Nenhum participante encontrado'), findsOneWidget);
  });

  testWidgets('mostra erro de participantes', (tester) async {
    await _pumpPicker(
      tester,
      initialRole: _role(roleId: 'role-1', name: 'Vocal'),
      participantsError: true,
    );

    expect(
      find.text('Não foi possível carregar os participantes.'),
      findsOneWidget,
    );
  });

  testWidgets('mostra loading de participantes', (tester) async {
    await _pumpPicker(
      tester,
      initialRole: _role(roleId: 'role-1', name: 'Vocal'),
      participantsLoading: true,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  LineupItemEntity? initialRole,
  List<DepartmentParticipantEntity>? participants,
  bool participantsError = false,
  bool participantsLoading = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        departmentParticipantsProvider.overrideWith((ref, departmentId) {
          if (participantsLoading) {
            return Completer<List<DepartmentParticipantEntity>>().future;
          }
          if (participantsError) {
            throw Exception('falha');
          }
          return Future.value(participants ?? _participants());
        }),
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://example.com/$imageId.png',
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ScaleAssignmentPickerBottomSheet(
            departmentId: 'dep-1',
            roles: [
              _role(roleId: 'role-1', name: 'Vocal'),
              _role(roleId: 'role-2', name: 'Violão'),
            ],
            initialRole: initialRole,
          ),
        ),
      ),
    ),
  );

  if (!participantsLoading) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }
}

LineupItemEntity _role({required String roleId, required String name}) {
  return LineupItemEntity(
    id: 'item-$roleId',
    lineupId: 'lineup-1',
    roleId: roleId,
    description: name,
    role: RoleEntity(id: roleId, name: name, slug: roleId),
  );
}

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
