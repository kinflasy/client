import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows custom labels and returns true on confirm', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showActionConfirmationDialog(
                    context,
                    title: 'Confirmar ação',
                    message: 'Deseja continuar?',
                    confirmLabel: 'Confirmar',
                    cancelLabel: 'Voltar',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar ação'), findsOneWidget);
    expect(find.text('Deseja continuar?'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('returns false on cancel', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showActionConfirmationDialog(
                    context,
                    title: 'Confirmar ação',
                    message: 'Deseja continuar?',
                    confirmLabel: 'Confirmar',
                    cancelLabel: 'Voltar',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
