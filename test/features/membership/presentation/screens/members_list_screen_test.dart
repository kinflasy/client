import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/presentation/screens/members_list_screen.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final members = [
    UnitMemberEntity(
      membershipId: '1',
      personId: 'p1',
      fullName: 'Ana Maria',
      affiliation: 'MEMBER',
      gender: 'FEMALE',
      birthDate: DateTime(1996, 4, 10),
      profileImageId: 'image-1',
    ),
    UnitMemberEntity(
      membershipId: '2',
      personId: 'p2',
      fullName: 'Bruno Lima',
      affiliation: 'VISITOR',
      gender: 'MALE',
      birthDate: DateTime(2008, 4, 10),
    ),
  ];

  testWidgets('applies and clears filters from bottom sheet', (tester) async {
    final container = ProviderContainer(
      overrides: [
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
        rawUnitMembersProvider.overrideWith((ref, unitId) async => members),
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://cdn.example/$imageId.png',
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MembersListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 pessoas'), findsOneWidget);
    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsNothing);
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byTooltip('Filtrar membros'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visitantes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulheres'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Aplicar'));
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('1 pessoas'), findsOneWidget);
    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.filter_list),
              matching: find.byType(IconButton),
            ),
          )
          .color,
      AppColors.primary,
    );
    expect(container.read(memberFilterProvider).gender, 'FEMALE');
    expect(container.read(memberFilterProvider).affiliations, {
      'MEMBER',
      'VISITOR',
    });

    await tester.tap(find.byTooltip('Filtrar membros'));
    await tester.pumpAndSettle();
    expect(container.read(memberFilterProvider).gender, 'FEMALE');

    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('1 pessoas'), findsOneWidget);
    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsNothing);
    expect(
      container.read(memberFilterProvider),
      MemberFilterState.defaultState,
    );
  });

  testWidgets('opens member detail using personId route', (tester) async {
    final container = ProviderContainer(
      overrides: [
        activeMembershipProvider.overrideWith(
          (ref) async => const MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ),
        rawUnitMembersProvider.overrideWith((ref, unitId) async => members),
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://cdn.example/$imageId.png',
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.peopleList,
      routes: [
        GoRoute(
          path: AppRoutes.peopleList,
          builder: (context, state) => const MembersListScreen(),
        ),
        GoRoute(
          path: AppRoutes.peopleDetail,
          name: AppRoutes.peopleDetailName,
          builder: (context, state) =>
              Text('opened:${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ana Maria'));
    await tester.pumpAndSettle();

    expect(find.text('opened:p1'), findsOneWidget);
  });
}
