import 'package:client/core/presentation/widgets/app_action_button.dart';
import 'package:client/core/presentation/widgets/app_action_button_thin.dart';
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

  testWidgets('AppActionButton renderiza titulo e icone', (tester) async {
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

  testWidgets('AppActionButton renderiza titulo centralizado sem icone', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(AppActionButton(title: 'Continuar', onTap: () {})),
    );

    final row = tester.widget<Row>(find.byType(Row));

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(row.mainAxisAlignment, MainAxisAlignment.center);
  });

  testWidgets('AppActionButton executa onTap', (tester) async {
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

  testWidgets('AppActionButton usa cor padrao do primaryContainer', (
    tester,
  ) async {
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

  testWidgets('AppActionButton respeita cores customizadas', (tester) async {
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

  testWidgets('AppActionButtonThin renderiza titulo e icone', (tester) async {
    await tester.pumpWidget(
      buildApp(
        AppActionButtonThin(
          icon: Icons.add,
          title: 'Nova escala',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Nova escala'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('AppActionButtonThin renderiza titulo sem icone', (tester) async {
    await tester.pumpWidget(
      buildApp(AppActionButtonThin(title: 'Continuar', onTap: () {})),
    );

    final row = tester.widget<Row>(find.byType(Row));

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(row.mainAxisAlignment, MainAxisAlignment.center);
  });

  testWidgets('AppActionButtonThin usa estilo padrao do ElevatedButton', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        AppActionButtonThin(
          icon: Icons.add,
          title: 'Nova escala',
          onTap: () {},
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(button.style, isNull);
  });

  testWidgets('AppActionButtonThin executa onTap', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      buildApp(
        AppActionButtonThin(
          icon: Icons.person_add_alt_1,
          title: 'Adicionar integrantes',
          onTap: () => tapCount++,
        ),
      ),
    );

    await tester.tap(find.text('Adicionar integrantes'));

    expect(tapCount, 1);
  });

  testWidgets('AppActionButtonThin respeita borda e sombra', (tester) async {
    const borderColor = Colors.blueGrey;
    const shadowColor = Colors.black26;

    await tester.pumpWidget(
      buildApp(
        AppActionButtonThin(
          icon: Icons.add,
          title: 'Criar evento',
          onTap: () {},
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          borderColor: borderColor,
          borderWidth: 1,
          elevation: 2,
          shadowColor: shadowColor,
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    final style = button.style!;
    final shape =
        style.shape!.resolve(const <WidgetState>{}) as RoundedRectangleBorder;

    expect(shape.side.color, borderColor);
    expect(shape.side.width, 1);
    expect(style.elevation!.resolve(const <WidgetState>{}), 2);
    expect(style.shadowColor!.resolve(const <WidgetState>{}), shadowColor);
  });
}
