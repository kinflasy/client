import 'package:client/core/presentation/forms/app_autofill_hints.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChurchInfoStep extends ConsumerWidget {
  final GlobalKey<FormState> formKey;

  const ChurchInfoStep({super.key, required this.formKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(registerChurchFormProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _field(
              'Nome da Igreja *',
              (v) => notifier.update((s) => s.copyWith(churchName: v)),
              autofillHints: AppAutofillHints.fullName,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo obrigat\u00f3rio' : null,
            ),
            _field(
              'Slug *',
              (v) => notifier.update((s) => s.copyWith(churchSlug: v)),
              hint: 'ex: minha-igreja',
              behavior: AppTextInputBehavior.lowercaseId,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo obrigat\u00f3rio' : null,
            ),
            _field(
              'Sigla',
              (v) => notifier.update((s) => s.copyWith(churchAcronym: v)),
              behavior: AppTextInputBehavior.uppercaseAcronym,
            ),
            _field(
              'Telefone',
              (v) => notifier.update((s) => s.copyWith(churchPhone: v)),
              hint: '(00) 00000-0000',
              keyboardType: TextInputType.phone,
              behavior: AppTextInputBehavior.plain,
              autofillHints: AppAutofillHints.phone,
              inputFormatters: const [BrazilianPhoneTextInputFormatter()],
              validator: _optionalPhoneValidator,
            ),
            _field(
              'E-mail *',
              (v) => notifier.update((s) => s.copyWith(churchEmail: v)),
              keyboardType: TextInputType.emailAddress,
              behavior: AppTextInputBehavior.emailLike,
              autofillHints: AppAutofillHints.email,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigat\u00f3rio';
                if (!v.contains('@')) return 'E-mail inv\u00e1lido';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    void Function(String) onChanged, {
    String? hint,
    TextInputType? keyboardType,
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: keyboardType,
        textCapitalization: behavior.textCapitalization,
        autocorrect: behavior.autocorrect,
        enableSuggestions: behavior.enableSuggestions,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  static String? _optionalPhoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return isCompleteBrazilianPhone(value) ? null : 'Telefone inv\u00e1lido';
  }
}
