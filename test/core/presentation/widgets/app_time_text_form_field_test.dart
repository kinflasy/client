import 'package:client/core/presentation/widgets/app_time_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseBrazilianTime accepts valid time', () {
    final time = parseBrazilianTime('09:30');

    expect(time?.hour, 9);
    expect(time?.minute, 30);
  });

  test('formatBrazilianTime formats with leading zeros', () {
    expect(formatBrazilianTime(const TimeOfDay(hour: 7, minute: 5)), '07:05');
  });

  testWidgets('campo aplica formatação HH:MM ao digitar', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTimeTextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Hora'),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '1830');
    await tester.pump();

    expect(controller.text, '18:30');
  });
}
