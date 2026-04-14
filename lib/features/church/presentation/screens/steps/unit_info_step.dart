import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
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
            _field(
              'Telefone *',
              _phoneController,
              (v) => notifier.update((s) => s.copyWith(unitPhone: v)),
              keyboardType: TextInputType.phone,
              behavior: AppTextInputBehavior.plain,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo obrigat\u00f3rio' : null,
            ),
            _field(
              'E-mail *',
              _emailController,
              (v) => notifier.update((s) => s.copyWith(unitEmail: v)),
              keyboardType: TextInputType.emailAddress,
              behavior: AppTextInputBehavior.emailLike,
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
    TextEditingController controller,
    void Function(String) onChanged, {
    String? hint,
    TextInputType? keyboardType,
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
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
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
