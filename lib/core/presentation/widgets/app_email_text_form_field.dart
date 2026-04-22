import 'package:client/core/presentation/forms/app_autofill_hints.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:flutter/material.dart';

class AppEmailTextFormField extends StatelessWidget {
  const AppEmailTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    required this.decoration,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.enabled,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final InputDecoration decoration;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      decoration: decoration,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: AppTextInputBehavior.emailLike.textCapitalization,
      autocorrect: AppTextInputBehavior.emailLike.autocorrect,
      enableSuggestions: AppTextInputBehavior.emailLike.enableSuggestions,
      autofillHints: AppAutofillHints.email,
      textInputAction: textInputAction,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
