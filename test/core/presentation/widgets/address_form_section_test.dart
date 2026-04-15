import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/presentation/widgets/address_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders all expected labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddressFormSection(
            value: const AddressFormState(),
            onChanged: _noop,
          ),
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

  testWidgets('editing a field emits updated state', (tester) async {
    AddressFormState? latestValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddressFormSection(
            value: const AddressFormState(),
            onChanged: (next) => latestValue = next,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '12345-678');

    expect(latestValue, isNotNull);
    expect(latestValue!.zip, '12345-678');
  });

  testWidgets('showTitle controls title visibility', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddressFormSection(
            value: const AddressFormState(),
            onChanged: _noop,
            title: 'Endereço da unidade',
            showTitle: true,
          ),
        ),
      ),
    );

    expect(find.text('Endereço da unidade'), findsOneWidget);
  });
}

void _noop(AddressFormState _) {}
