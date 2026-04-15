import 'package:client/features/church/presentation/screens/steps/address_step.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders shared address fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddressStep(formKey: GlobalKey<FormState>())),
        ),
      ),
    );

    expect(find.text('CEP'), findsOneWidget);
    expect(find.text('País'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Cidade'), findsOneWidget);
    expect(find.text('Bairro'), findsOneWidget);
    expect(find.text('Rua'), findsOneWidget);
    expect(find.text('Número'), findsOneWidget);
    expect(find.text('Complemento'), findsOneWidget);
    expect(find.text('Referência'), findsOneWidget);
  });

  testWidgets('updates provider state when editing a field', (tester) async {
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              home: Scaffold(body: AddressStep(formKey: GlobalKey<FormState>())),
            );
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '12345-678');

    expect(container.read(registerChurchFormProvider).address.zip, '12345-678');
  });
}
