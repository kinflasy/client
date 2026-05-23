import 'package:client/core/presentation/widgets/app_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renderiza título e ícone', (tester) async {
    await tester.pumpWidget(
      buildApp(
        AppActionButton(
          icon: Icons.edit_outlined,
          title: 'Editar',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Editar'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('executa onTap', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      buildApp(
        AppActionButton(
          icon: Icons.edit_outlined,
          title: 'Editar',
          onTap: () => tapCount++,
        ),
      ),
    );

    await tester.tap(find.text('Editar'));

    expect(tapCount, 1);
  });

  testWidgets('usa cor padrão do primaryContainer', (tester) async {
    await tester.pumpWidget(
      buildApp(
        AppActionButton(
          icon: Icons.edit_outlined,
          title: 'Editar',
          onTap: () {},
        ),
      ),
    );

    final context = tester.element(find.byType(AppActionButton));
    final expectedColor = Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: 0.72);
    final ink = tester.widget<Ink>(find.byType(Ink));
    final decoration = ink.decoration! as BoxDecoration;

    expect(decoration.color, expectedColor);
  });

  testWidgets('respeita cores customizadas', (tester) async {
    const backgroundColor = Colors.purple;
    const foregroundColor = Colors.white;

    await tester.pumpWidget(
      buildApp(
        AppActionButton(
          icon: Icons.edit_outlined,
          title: 'Editar',
          onTap: () {},
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
      ),
    );

    final ink = tester.widget<Ink>(find.byType(Ink));
    final decoration = ink.decoration! as BoxDecoration;
    final icon = tester.widget<Icon>(find.byIcon(Icons.edit_outlined));
    final text = tester.widget<Text>(find.text('Editar'));

    expect(decoration.color, backgroundColor.withValues(alpha: 0.72));
    expect(icon.color, foregroundColor);
    expect(text.style?.color, foregroundColor);
  });
}
