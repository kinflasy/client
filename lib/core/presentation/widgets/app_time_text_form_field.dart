import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTimeTextFormField extends StatelessWidget {
  const AppTimeTextFormField({
    super.key,
    required this.controller,
    required this.decoration,
    this.onChanged,
    this.validator,
    this.onPicked,
    this.initialTime,
    this.textInputAction,
    this.enabled,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final ValueChanged<TimeOfDay>? onPicked;
  final TimeOfDay? initialTime;
  final TextInputAction? textInputAction;
  final bool? enabled;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          initialTime ?? parseBrazilianTime(controller.text) ?? TimeOfDay.now(),
    );
    if (picked == null) return;

    controller.text = formatBrazilianTime(picked);
    onPicked?.call(picked);
    onChanged?.call(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled ?? true;
    return TextFormField(
      controller: controller,
      decoration: decoration.copyWith(
        hintText: decoration.hintText ?? 'HH:MM',
        suffixIcon:
            decoration.suffixIcon ??
            IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: isEnabled ? () => _pickTime(context) : null,
            ),
      ),
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        const TimeTextInputFormatter(),
      ],
      textInputAction: textInputAction,
      enabled: isEnabled,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

TimeOfDay? parseBrazilianTime(String value) {
  final digits = digitsOnly(value);
  if (digits.length != 4) return null;

  final hour = int.tryParse(digits.substring(0, 2));
  final minute = int.tryParse(digits.substring(2, 4));
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  return TimeOfDay(hour: hour, minute: minute);
}

String formatBrazilianTime(TimeOfDay? time) {
  if (time == null) return '';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class TimeTextInputFormatter extends TextInputFormatter {
  const TimeTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length && i < 4; i++) {
      buffer.write(digits[i]);
      if (i == 1 && i != digits.length - 1) {
        buffer.write(':');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
