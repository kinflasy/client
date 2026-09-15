import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/data/models/activate_member_request_model.dart';
import 'package:client/features/membership/data/models/register_member_request_model.dart';
import 'package:client/features/membership/domain/entities/activation_user_entity.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:client/features/membership/domain/repositories/unit_member_repository.dart';
import 'package:client/features/membership/presentation/screens/activate_member_screen.dart';
import 'package:client/features/membership/providers/register_member_providers.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toastification/toastification.dart';

class _MockUnitMemberRepository extends Mock implements UnitMemberRepository {}

class _FakeActivateMemberRequestModel extends Fake
    implements ActivateMemberRequestModel {}

class _FakeRegisterMemberRequestModel extends Fake
    implements RegisterMemberRequestModel {}

void main() {
  late _MockUnitMemberRepository repository;

  final inactiveMember = UnitMemberEntity(
    membershipId: 'membership-1',
    personId: 'person-1',
    personType: PersonType.inactive,
    fullName: 'Carlos Lima',
    affiliation: 'MEMBER',
    gender: 'MALE',
  );

  final activeMember = UnitMemberEntity(
    membershipId: 'membership-2',
    personId: 'person-2',
    personType: PersonType.user,
    fullName: 'Ana Maria',
    affiliation: 'MEMBER',
    gender: 'FEMALE',
  );

  const initialProfile = MemberProfileEntity(
    personId: 'person-1',
    membershipId: 'membership-1',
    personType: PersonType.inactive,
    fullName: 'Carlos Lima',
    gender: 'MALE',
    affiliation: 'MEMBER',
    integrations: [],
  );

  setUpAll(() {
    registerFallbackValue(_FakeActivateMemberRequestModel());
    registerFallbackValue(_FakeRegisterMemberRequestModel());
  });

  setUp(() {
    repository = _MockUnitMemberRepository();
  });

  testWidgets('lists only inactive people for selection', (tester) async {
    await _pumpScreen(
      tester,
      repository: repository,
      members: [inactiveMember, activeMember],
    );

    await tester.tap(find.byType(DropdownButtonFormField<UnitMemberEntity>));
    await tester.pumpAndSettle();

    expect(find.text('Carlos Lima'), findsOneWidget);
    expect(find.text('Ana Maria'), findsNothing);
  });

  testWidgets('searches user and activates selected inactive person', (
    tester,
  ) async {
    when(() => repository.identifyUserByUsername('ana')).thenAnswer(
      (_) async => const Right(
        ActivationUserEntity(id: 'user-1', username: 'ana', nickname: 'Aninha'),
      ),
    );
    when(
      () => repository.activateMember(any()),
    ).thenAnswer((_) async => const Right(null));

    await _pumpScreen(
      tester,
      repository: repository,
      members: [inactiveMember],
      initialProfile: initialProfile,
    );

    await tester.enterText(find.byType(TextFormField), '@ana');
    await tester.tap(find.byTooltip('Buscar usuário'));
    await tester.pumpAndSettle();

    expect(find.text('Aninha'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Vincular usuário'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    final captured =
        verify(() => repository.activateMember(captureAny())).captured.single
            as ActivateMemberRequestModel;
    expect(captured.inactivePersonId, 'person-1');
    expect(captured.username, 'ana');
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockUnitMemberRepository repository,
  required List<UnitMemberEntity> members,
  MemberProfileEntity? initialProfile,
}) async {
  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.push('/activate'),
              child: const Text('open-activate'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) =>
            ActivateMemberScreen(initialProfile: initialProfile),
      ),
    ],
  );

  await tester.pumpWidget(
    ToastificationWrapper(
      child: ProviderScope(
        overrides: [
          unitMemberRepositoryProvider.overrideWithValue(repository),
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-active',
              unitId: 'unit-1',
              affiliation: 'UNIT_ADMIN',
            ),
          ),
          rawUnitMembersProvider.overrideWith((ref, unitId) async => members),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open-activate'));
  await tester.pumpAndSettle();
}
