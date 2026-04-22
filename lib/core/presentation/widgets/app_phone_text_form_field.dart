import 'package:client/core/presentation/forms/app_autofill_hints.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppPhoneTextFormField extends StatelessWidget {
  const AppPhoneTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    required this.decoration,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.enabled,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final InputDecoration decoration;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final bool? enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      decoration: decoration.copyWith(
        hintText: decoration.hintText ?? '(00) 00000-0000',
      ),
      keyboardType: TextInputType.phone,
      textCapitalization: AppTextInputBehavior.plain.textCapitalization,
      autocorrect: AppTextInputBehavior.plain.autocorrect,
      enableSuggestions: AppTextInputBehavior.plain.enableSuggestions,
      autofillHints: AppAutofillHints.phone,
      inputFormatters:
          inputFormatters ?? const [BrazilianPhoneTextInputFormatter()],
      textInputAction: textInputAction,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
