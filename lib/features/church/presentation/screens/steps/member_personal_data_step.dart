import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/features/membership/providers/register_member_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberPersonalDataStep extends ConsumerStatefulWidget {
  const MemberPersonalDataStep({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<MemberPersonalDataStep> createState() =>
      _MemberPersonalDataStepState();
}

class _MemberPersonalDataStepState
    extends ConsumerState<MemberPersonalDataStep> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registerMemberFormProvider);
    _fullNameController = TextEditingController(text: formState.fullName);
    _nicknameController = TextEditingController(text: formState.nickname);
    _birthDateController = TextEditingController(
      text: _formatDate(formState.birthDate),
    );
    _phoneController = TextEditingController(text: formState.phone);
    _emailController = TextEditingController(text: formState.email);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registerMemberFormProvider);
    final notifier = ref.read(registerMemberFormProvider.notifier);

    final formattedBirthDate = _formatDate(formState.birthDate);
    if (_birthDateController.text != formattedBirthDate) {
      _birthDateController.text = formattedBirthDate;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            _field(
              label: 'Nome completo *',
              controller: _fullNameController,
              onChanged: (value) =>
                  notifier.updatePersonalData(fullName: value),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obrigat\u00f3rio';
                }
                return null;
              },
            ),
            _field(
              label: 'Apelido',
              controller: _nicknameController,
              onChanged: (value) =>
                  notifier.updatePersonalData(nickname: value),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                initialValue: formState.gender,
                decoration: _inputDecoration('G\u00eanero *'),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Masculino')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Feminino')),
                ],
                onChanged: (value) =>
                    notifier.updatePersonalData(gender: value),
                validator: (value) =>
                    value == null ? 'Campo obrigat\u00f3rio' : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _birthDateController,
                readOnly: true,
                decoration: _inputDecoration('Data de nascimento *').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            formState.birthDate ??
                            DateTime(DateTime.now().year - 18),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        notifier.updatePersonalData(birthDate: picked);
                      }
                    },
                  ),
                ),
                validator: (_) => formState.birthDate == null
                    ? 'Campo obrigat\u00f3rio'
                    : null,
              ),
            ),
            _field(
              label: 'Telefone',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              behavior: AppTextInputBehavior.plain,
              onChanged: (value) => notifier.updatePersonalData(phone: value),
            ),
            _field(
              label: 'E-mail',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              behavior: AppTextInputBehavior.emailLike,
              onChanged: (value) => notifier.updatePersonalData(email: value),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                return emailRegex.hasMatch(value.trim())
                    ? null
                    : 'E-mail inv\u00e1lido';
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required void Function(String) onChanged,
    TextInputType? keyboardType,
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        keyboardType: keyboardType,
        textCapitalization: behavior.textCapitalization,
        autocorrect: behavior.autocorrect,
        enableSuggestions: behavior.enableSuggestions,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
