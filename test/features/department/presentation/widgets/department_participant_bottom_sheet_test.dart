import 'dart:async';

import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/presentation/widgets/department_participant_bottom_sheet.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/membership/data/models/person_profile_model.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _participant = DepartmentParticipantEntity(
  personId: 'person-1',
  membershipId: 'membership-1',
  integrationType: IntegrationType.leader,
  nickname: 'Maria',
  affiliation: 'MEMBER',
  gender: 'FEMALE',
);

const _person = PersonProfileModel(
  type: PersonType.user,
  id: 'person-1',
  fullName: 'Maria Silva',
  nickname: 'Maria',
  gender: 'FEMALE',
  phone: '(85) 99999-0000',
  profileImageId: 'image-1',
);

void main() {
  testWidgets('renders loading state', (tester) async {
    final completer = Completer<PersonProfileModel>();

    await _pumpSheet(
      tester,
      providerOverride: departmentParticipantPersonProvider.overrideWith(
        (ref, personId) => completer.future,
      ),
    );

    expect(find.text('Carregando detalhes do participante...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders error state', (tester) async {
    await _pumpSheet(
      tester,
      providerOverride: departmentParticipantPersonProvider.overrideWith(
        (ref, personId) => Future.error(Exception('falha')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os detalhes do participante.'),
      findsOneWidget,
    );
    expect(find.text('Tente novamente em instantes.'), findsOneWidget);
  });

  testWidgets('renders nickname, phone, role and avatar', (tester) async {
    await _pumpSheet(
      tester,
      providerOverride: departmentParticipantPersonProvider.overrideWith(
        (ref, personId) async => _person,
      ),
    );
    await tester.pump();

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('(85) 99999-0000'), findsOneWidget);
    expect(find.text('Líder'), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
  });

  testWidgets('keeps layout valid when phone is absent', (tester) async {
    await _pumpSheet(
      tester,
      providerOverride: departmentParticipantPersonProvider.overrideWith(
        (ref, personId) async => const PersonProfileModel(
          type: PersonType.user,
          id: 'person-1',
          fullName: 'Maria Silva',
          nickname: 'Maria',
          gender: 'FEMALE',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Líder'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
  });

  test('translates all integration roles', () {
    expect(translateIntegrationType(IntegrationType.observer), 'Observador');
    expect(translateIntegrationType(IntegrationType.consultant), 'Consultor');
    expect(translateIntegrationType(IntegrationType.integrant), 'Integrante');
    expect(translateIntegrationType(IntegrationType.assistant), 'Assistente');
    expect(translateIntegrationType(IntegrationType.leader), 'Líder');
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required providerOverride,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        providerOverride,
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
                  participant: _participant,
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
