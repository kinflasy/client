import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/presentation/widgets/address_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders all expected labels', (tester) async {
    await _pumpAddressForm(
      tester,
      value: const AddressFormState(),
      onChanged: _noop,
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

    await _pumpAddressForm(
      tester,
      value: const AddressFormState(),
      onChanged: (next) => latestValue = next,
    );

    await tester.enterText(find.byType(TextFormField).first, '12345-678');

    expect(latestValue, isNotNull);
    expect(latestValue!.zip, '12345-678');
  });

  testWidgets('updates visible fields when value changes after first build', (
    tester,
  ) async {
    await _pumpAddressForm(
      tester,
      value: const AddressFormState(),
      onChanged: _noop,
    );

    expect(find.text('60000-000'), findsNothing);
    expect(find.text('Fortaleza'), findsNothing);
    expect(find.text('Rua A'), findsNothing);

    await _pumpAddressForm(
      tester,
      value: const AddressFormState(
        zip: '60000-000',
        city: 'Fortaleza',
        street: 'Rua A',
      ),
      onChanged: _noop,
    );
    await tester.pump();

    expect(find.text('60000-000'), findsOneWidget);
    expect(find.text('Fortaleza'), findsOneWidget);
    expect(find.text('Rua A'), findsOneWidget);
  });

  testWidgets('showTitle controls title visibility', (tester) async {
    await _pumpAddressForm(
      tester,
      value: const AddressFormState(),
      onChanged: _noop,
      title: 'Endereço da unidade',
      showTitle: true,
    );

    expect(find.text('Endereço da unidade'), findsOneWidget);
  });

  testWidgets('keeps focus while parent rebuilds after typing', (tester) async {
    var value = const AddressFormState();

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: SingleChildScrollView(
                child: AddressFormSection(
                  value: value,
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '1');
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(editable.focusNode.hasFocus, isTrue);
    expect(value.zip, '1');
  });
}

void _noop(AddressFormState _) {}

Future<void> _pumpAddressForm(
  WidgetTester tester, {
  required AddressFormState value,
  required ValueChanged<AddressFormState> onChanged,
  String? title,
  bool showTitle = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AddressFormSection(
            value: value,
            onChanged: onChanged,
            title: title,
            showTitle: showTitle,
          ),
        ),
      ),
    ),
  );
}
