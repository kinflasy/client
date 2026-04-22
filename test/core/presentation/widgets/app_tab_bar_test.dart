import 'dart:ui';

import 'package:client/core/config/theme/app_theme.dart';
import 'package:client/core/presentation/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders tabs and changes selection when tapped', (tester) async {
    var selectedIndex = 0;
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      buildApp(
        StatefulBuilder(
          builder: (context, setState) {
            return AppTabBar(
              tabs: const ['Visão geral', 'Eventos', 'Avisos'],
              selectedIndex: selectedIndex,
              onTabChanged: (index) => setState(() => selectedIndex = index),
            );
          },
        ),
      ),
    );

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Avisos'), findsOneWidget);

    await tester.tap(find.text('Eventos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final node = tester.getSemantics(find.text('Eventos'));
    // ignore: deprecated_member_use
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
    // ignore: deprecated_member_use
    expect(node.hasFlag(SemanticsFlag.isSelected), isTrue);

    semanticsHandle.dispose();
  });

  testWidgets('uses expanded mode when tabs fit the available width', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        Center(
          child: SizedBox(
            width: 420,
            child: AppTabBar(
              tabs: ['Feed', 'Agenda', 'Igreja'],
              selectedIndex: 0,
              onTabChanged: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('app-tab-bar-scroll-view')), findsNothing);
  });

  testWidgets('uses horizontal scroll mode when tabs overflow', (tester) async {
    await tester.pumpWidget(
      buildApp(
        Center(
          child: SizedBox(
            width: 220,
            child: AppTabBar(
              tabs: [
                'Visão geral',
                'Próximos eventos',
                'Comunicados da igreja',
                'Departamentos',
              ],
              selectedIndex: 0,
              onTabChanged: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('app-tab-bar-scroll-view')), findsOneWidget);
  });

  testWidgets('asserts when selectedIndex is outside the tabs range', (
    tester,
  ) async {
    expect(
      () => tester.pumpWidget(
        buildApp(
          AppTabBar(
            tabs: ['Feed', 'Agenda'],
            selectedIndex: 2,
            onTabChanged: _noop,
          ),
        ),
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}

void _noop(int _) {}
