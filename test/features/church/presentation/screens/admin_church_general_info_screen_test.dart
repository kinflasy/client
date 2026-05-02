import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/domain/entities/church_link_entity.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/presentation/screens/admin_church_general_info_screen.dart';
import 'package:client/features/church/providers/church_general_info_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminChurchGeneralInfoScreen', () {
    const mockChurch = ChurchEntity(
      id: 'church-1',
      name: 'Igreja Batista Betel',
      slug: 'betel',
      acronym: 'IBB',
      phone: '(11) 1234-5678',
      email: 'contact@betel.com',
      coverUrl: null,
      logoUrl: null,
      address: 'Rua Principal, 123',
      website: 'https://betel.com',
      instagramUrl: null,
      youtubeUrl: null,
      spotifyUrl: null,
      whatsappNumber: null,
    );

    const mockUnit = ChurchUnitEntity(
      id: 'unit-1',
      churchId: 'church-1',
      name: 'Sede',
      slug: 'sede',
      type: 'MAIN',
      address: 'Rua Principal, 123, São Paulo, SP',
      phone: '(11) 1234-5678',
      email: 'sede@betel.com',
      logoUrl: null,
      coverUrl: null,
    );

    const mockMembership = MembershipEntity(
      id: 'membership-1',
      unitId: 'unit-1',
      affiliation: 'UNIT_ADMIN',
    );

    ProviderContainer buildContainerWithProfile(
      CurrentChurchProfileEntity profile, {
      List<ChurchLinkEntity> links = const [],
    }) {
      return ProviderContainer(
        overrides: [
          currentChurchProfileProvider.overrideWith((ref) async => profile),
          unitLinksProvider.overrideWith((ref, unitId) async => links),
        ],
      );
    }

    testWidgets('shows error state with retry button on failure', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          currentChurchProfileProvider.overrideWith(
            (ref) async =>
                throw const NotFoundFailure('Nenhuma igreja vinculada.'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AdminChurchGeneralInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Erro ao carregar informações'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('displays identity block with data', (tester) async {
      final container = buildContainerWithProfile(
        const CurrentChurchProfileEntity(
          membership: mockMembership,
          unit: mockUnit,
          church: mockChurch,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AdminChurchGeneralInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Identidade block
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('Identidade'), findsWidgets);
      expect(find.text('Sede', skipOffstage: false), findsWidgets);
    });

    testWidgets('falls back to church identity when unit data is missing', (
      tester,
    ) async {
      const fallbackUnit = ChurchUnitEntity(
        id: 'unit-3',
        churchId: 'church-1',
        name: null,
        slug: null,
        type: 'MAIN',
        address: 'Rua Principal, 123, São Paulo, SP',
        phone: null,
        email: null,
        logoUrl: null,
        coverUrl: null,
      );

      final container = buildContainerWithProfile(
        const CurrentChurchProfileEntity(
          membership: mockMembership,
          unit: fallbackUnit,
          church: mockChurch,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AdminChurchGeneralInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Igreja Batista Betel'), findsWidgets);
      expect(find.text('betel'), findsWidgets);
      expect(find.text('—', skipOffstage: false), findsNothing);
    });

    testWidgets('displays address info correctly', (tester) async {
      final container = buildContainerWithProfile(
        const CurrentChurchProfileEntity(
          membership: mockMembership,
          unit: mockUnit,
          church: mockChurch,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AdminChurchGeneralInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rua Principal, 123, São Paulo, SP'), findsOneWidget);
    });

    testWidgets('shows empty state for address when null', (tester) async {
      const unitWithoutAddress = ChurchUnitEntity(
        id: 'unit-2',
        churchId: 'church-1',
        name: 'Filial',
        slug: 'filial',
        type: 'SECONDARY',
        address: null,
        phone: null,
        email: null,
        logoUrl: null,
        coverUrl: null,
      );

      final container = buildContainerWithProfile(
        const CurrentChurchProfileEntity(
          membership: mockMembership,
          unit: unitWithoutAddress,
          church: mockChurch,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AdminChurchGeneralInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum endereço cadastrado.'), findsOneWidget);
    });

    testWidgets('shows empty state for links', (tester) async {
      final container = buildContainerWithProfile(
        const CurrentChurchProfileEntity(
          membership: mockMembership,
          unit: mockUnit,
          church: mockChurch,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AdminChurchGeneralInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum link cadastrado.', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('shows at most three links in the summary', (tester) async {
      final container = buildContainerWithProfile(
        const CurrentChurchProfileEntity(
          membership: mockMembership,
          unit: mockUnit,
          church: mockChurch,
        ),
        links: const [
          ChurchLinkEntity(
            id: 'link-1',
            label: 'Website',
            url: 'https://example.com/1',
          ),
          ChurchLinkEntity(
            id: 'link-2',
            label: 'Instagram',
            url: 'https://example.com/2',
          ),
          ChurchLinkEntity(
            id: 'link-3',
            label: 'YouTube',
            url: 'https://example.com/3',
          ),
          ChurchLinkEntity(
            id: 'link-4',
            label: 'Spotify',
            url: 'https://example.com/4',
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AdminChurchGeneralInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Website', skipOffstage: false), findsOneWidget);
      expect(find.text('Instagram', skipOffstage: false), findsOneWidget);
      expect(find.text('YouTube', skipOffstage: false), findsOneWidget);
      expect(find.text('Spotify', skipOffstage: false), findsNothing);
      expect(
        find.text('https://example.com/4', skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('displays title and all section headers', (tester) async {
      final container = buildContainerWithProfile(
        const CurrentChurchProfileEntity(
          membership: mockMembership,
          unit: mockUnit,
          church: mockChurch,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AdminChurchGeneralInfoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Informações gerais'), findsOneWidget);
      expect(find.text('Identidade', skipOffstage: false), findsOneWidget);
      expect(find.text('Endereço', skipOffstage: false), findsOneWidget);
      expect(find.text('Links externos', skipOffstage: false), findsOneWidget);
    });
  });
}
