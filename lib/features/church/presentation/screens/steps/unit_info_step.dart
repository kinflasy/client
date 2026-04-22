import 'package:client/core/presentation/forms/app_autofill_hints.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/core/presentation/widgets/app_email_text_form_field.dart';
import 'package:client/core/presentation/widgets/app_phone_text_form_field.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitInfoStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;

  const UnitInfoStep({super.key, required this.formKey});

  @override
  ConsumerState<UnitInfoStep> createState() => _UnitInfoStepState();
}

class _UnitInfoStepState extends ConsumerState<UnitInfoStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registerChurchFormProvider);
    _nameController = TextEditingController(text: formState.churchName);
    _slugController = TextEditingController(text: formState.churchSlug);
    _phoneController = TextEditingController(text: formState.churchPhone);
    _emailController = TextEditingController(text: formState.churchEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(registerChurchFormProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            _field(
              'Nome da Sede *',
              _nameController,
              (v) => notifier.update((s) => s.copyWith(unitName: v)),
              autofillHints: AppAutofillHints.fullName,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo obrigat\u00f3rio' : null,
            ),
            _field(
              'Slug *',
              _slugController,
              (v) => notifier.update((s) => s.copyWith(unitSlug: v)),
              hint: 'ex: sede-central',
              behavior: AppTextInputBehavior.lowercaseId,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo obrigat\u00f3rio' : null,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppPhoneTextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '(00) 00000-0000',
                ),
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(unitPhone: v)),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Campo obrigat\u00f3rio'
                    : isCompleteBrazilianPhone(v)
                    ? null
                    : 'Telefone inv\u00e1lido',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppEmailTextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(unitEmail: v)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigat\u00f3rio';
                  if (!v.contains('@')) return 'E-mail inv\u00e1lido';
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    void Function(String) onChanged, {
    String? hint,
    TextInputType? keyboardType,
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
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
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
