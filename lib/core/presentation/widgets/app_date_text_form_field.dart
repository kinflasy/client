import 'package:client/core/presentation/forms/app_autofill_hints.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppDateTextFormField extends StatelessWidget {
  const AppDateTextFormField({
    super.key,
    required this.controller,
    required this.decoration,
    this.onChanged,
    this.validator,
    this.onPicked,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.textInputAction,
    this.enabled,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final ValueChanged<DateTime>? onPicked;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final TextInputAction? textInputAction;
  final bool? enabled;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? now,
    );
    if (picked == null) return;

    controller.text = formatBrazilianDate(picked);
    onPicked?.call(picked);
    onChanged?.call(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled ?? true;
    return TextFormField(
      controller: controller,
      decoration: decoration.copyWith(
        hintText: decoration.hintText ?? 'DD/MM/AAAA',
        suffixIcon:
            decoration.suffixIcon ??
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: isEnabled ? () => _pickDate(context) : null,
            ),
      ),
      keyboardType: TextInputType.datetime,
      autofillHints: AppAutofillHints.birthDate,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        const DateTextInputFormatter(),
      ],
      textInputAction: textInputAction,
      enabled: isEnabled,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
