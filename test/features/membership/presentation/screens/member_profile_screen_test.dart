import 'package:client/core/errors/failure.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:client/features/membership/presentation/screens/member_profile_screen.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  MemberProfileEntity buildUserProfile() {
    return MemberProfileEntity(
      personId: 'person-1',
      membershipId: 'membership-1',
      personType: PersonType.user,
      fullName: 'Ana Maria',
      nickname: 'Aninha',
      gender: 'FEMALE',
      age: 36,
      phone: '(11) 99999-0000',
      email: 'ana@dev.com',
      address: 'Rua A, 10, Fortaleza, CE',
      addressDetails: const AddressDetailsEntity(
        id: 'address-1',
        street: 'Rua A',
        number: '10',
        city: 'Fortaleza',
        state: 'CE',
      ),
      affiliation: 'MEMBER',
      entryDate: DateTime(2020, 4, 10),
      profileImageId: 'image-1',
      integrations: const [
        MemberProfileIntegrationEntity(
          departmentId: 'dept-1',
          departmentName: 'Louvor',
          departmentType: 'MINISTRY',
          integrationType: IntegrationType.leader,
        ),
      ],
    );
  }

  MemberProfileEntity buildInactiveProfile() {
    return const MemberProfileEntity(
      personId: 'person-2',
      membershipId: 'membership-2',
      personType: PersonType.inactive,
      fullName: 'Carlos Lima',
      gender: 'MALE',
      age: 41,
      affiliation: 'VISITOR',
      integrations: [],
    );
  }

  testWidgets('renders user profile sections and chip', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberProfileProvider.overrideWith(
            (ref, personId) async => buildUserProfile(),
          ),
          mediaImageUrlProvider.overrideWith(
            (ref, imageId) async => 'https://cdn.example/$imageId.png',
          ),
        ],
        child: const MaterialApp(
          home: MemberProfileScreen(personId: 'person-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.text('Usuario do app'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('ana@dev.com'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rua A, 10, Fortaleza, CE'), 200);
    expect(find.text('Rua A, 10, Fortaleza, CE'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('10/04/2020'), 200);
    expect(find.text('10/04/2020'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Louvor'), 200);
    expect(find.textContaining('Louvor'), findsOneWidget);
    expect(find.text('Editar cadastro'), findsNothing);
  });

  testWidgets('renders inactive profile with edit button only', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberProfileProvider.overrideWith(
            (ref, personId) async => buildInactiveProfile(),
          ),
        ],
        child: const MaterialApp(
          home: MemberProfileScreen(personId: 'person-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pessoa inativa'), findsOneWidget);
    expect(find.text('Editar cadastro'), findsOneWidget);
    expect(find.text('Contato'), findsNothing);
  });

  testWidgets('shows friendly error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberProfileProvider.overrideWith(
            (ref, personId) => Future<MemberProfileEntity>.error(
              const NotFoundFailure(
                'Pessoa sem membresia ativa na unidade atual.',
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MemberProfileScreen(personId: 'person-3'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Pessoa sem membresia ativa na unidade atual.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('route works without extra by resolving from path param', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/people/person-1'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.peopleDetail,
          name: AppRoutes.peopleDetailName,
          builder: (context, state) =>
              MemberProfileScreen(personId: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberProfileProvider.overrideWith(
            (ref, personId) async => buildUserProfile(),
          ),
          mediaImageUrlProvider.overrideWith(
            (ref, imageId) async => 'https://cdn.example/$imageId.png',
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.text('Usuario do app'), findsOneWidget);
  });

  testWidgets('edit button navigates to edit route with personId', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.peopleDetail.replaceFirst(':id', 'person-2'),
      routes: [
        GoRoute(
          path: AppRoutes.peopleDetail,
          name: AppRoutes.peopleDetailName,
          builder: (context, state) =>
              MemberProfileScreen(personId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoutes.peopleEdit,
          name: AppRoutes.peopleEditName,
          builder: (context, state) =>
              Text('editing:${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberProfileProvider.overrideWith(
            (ref, personId) async => buildInactiveProfile(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar cadastro'));
    await tester.pumpAndSettle();

    expect(find.text('editing:person-2'), findsOneWidget);
  });
}
