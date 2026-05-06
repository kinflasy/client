import 'package:client/features/church/data/models/church_link_models.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_link_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/presentation/screens/edit_church_unit_links_screen.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

class _FakeChurchLinkRequestModel extends Fake
    implements ChurchLinkRequestModel {}

void main() {
  late _MockChurchUnitRepository repository;
  late List<ChurchLinkEntity> links;

  const church = ChurchEntity(
    id: 'church-1',
    name: 'Igreja Central',
    slug: 'igreja-central',
    email: 'contato@igreja.dev',
  );

  const unit = ChurchUnitEntity(
    id: 'unit-1',
    churchId: 'church-1',
    type: 'MAIN',
  );

  const profile = CurrentChurchProfileEntity(
    membership: MembershipEntity(
      id: 'membership-1',
      unitId: 'unit-1',
      affiliation: 'UNIT_ADMIN',
    ),
    unit: unit,
    church: church,
  );

  setUpAll(() {
    registerFallbackValue(_FakeChurchLinkRequestModel());
  });

  setUp(() {
    repository = _MockChurchUnitRepository();
    links = [];

    when(() => repository.getUnitLinks('unit-1')).thenAnswer(
      (_) async => Right(List<ChurchLinkEntity>.unmodifiable(links)),
    );

    when(
      () => repository.createUnitLink(
        'unit-1',
        any(that: isA<ChurchLinkRequestModel>()),
      ),
    ).thenAnswer((invocation) async {
      final request =
          invocation.positionalArguments[1] as ChurchLinkRequestModel;
      final created = ChurchLinkEntity(
        id: 'link-${links.length + 1}',
        label: request.label,
        url: request.url,
      );
      links = [...links, created];
      return Right(created);
    });

    when(
      () => repository.updateLink(
        'link-1',
        any(that: isA<ChurchLinkRequestModel>()),
      ),
    ).thenAnswer((invocation) async {
      final request =
          invocation.positionalArguments[1] as ChurchLinkRequestModel;
      final updated = ChurchLinkEntity(
        id: 'link-1',
        label: request.label,
        url: request.url,
      );
      links = [
        for (final link in links)
          if (link.id == 'link-1') updated else link,
      ];
      return Right(updated);
    });

    when(() => repository.deleteLink('link-1')).thenAnswer((_) async {
      links = links.where((link) => link.id != 'link-1').toList();
      return const Right(null);
    });
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        churchUnitRepositoryProvider.overrideWithValue(repository),
        currentChurchProfileProvider.overrideWith((ref) async => profile),
      ],
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: EditChurchUnitLinksScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when no links exist', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpScreen(tester, container);

    expect(find.text('Nenhum link cadastrado.'), findsOneWidget);
    expect(find.text('Adicionar primeiro link'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('renders existing links', (tester) async {
    links = const [
      ChurchLinkEntity(
        id: 'link-1',
        label: 'Website',
        url: 'https://igreja.dev',
      ),
      ChurchLinkEntity(
        id: 'link-2',
        label: 'Instagram',
        url: 'https://instagram.com/igreja',
      ),
    ];

    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpScreen(tester, container);

    expect(find.text('Website'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('https://igreja.dev'), findsOneWidget);
    expect(find.text('https://instagram.com/igreja'), findsOneWidget);
  });

  testWidgets('adds a link from bottom sheet and refreshes the list', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpScreen(tester, container);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Site oficial');
    await tester.enterText(find.byType(TextField).at(1), 'https://igreja.dev');
    await tester.tap(find.text('Adicionar link'));
    await tester.pumpAndSettle();

    expect(find.text('Link criado com sucesso.'), findsOneWidget);
    expect(find.text('Site oficial'), findsOneWidget);
    expect(find.text('https://igreja.dev'), findsOneWidget);
  });

  testWidgets('edits a link inline', (tester) async {
    links = const [
      ChurchLinkEntity(
        id: 'link-1',
        label: 'Website',
        url: 'https://igreja.dev',
      ),
    ];

    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpScreen(tester, container);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Site oficial');
    await tester.enterText(
      find.byType(TextField).at(1),
      'https://nova-igreja.dev',
    );
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('Link atualizado com sucesso.'), findsOneWidget);
    expect(find.text('Site oficial'), findsOneWidget);
    expect(find.text('https://nova-igreja.dev'), findsOneWidget);
    expect(find.text('Website'), findsNothing);
  });

  testWidgets('removes a link after confirmation', (tester) async {
    links = const [
      ChurchLinkEntity(
        id: 'link-1',
        label: 'Website',
        url: 'https://igreja.dev',
      ),
    ];

    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpScreen(tester, container);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(find.text('Link removido.'), findsOneWidget);
    expect(find.text('Nenhum link cadastrado.'), findsOneWidget);
  });
}
