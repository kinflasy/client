import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';

class UnitInfoStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;

  const UnitInfoStep({
    super.key,
    required this.formKey,
  });

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
    // Lê o estado atual do formulário direto do provider.
    // Neste momento o usuário já preencheu a Etapa 1, então os valores estão populados.
    final formState = ref.read(registerChurchFormProvider);
    _nameController  = TextEditingController(text: formState.churchName);
    _slugController  = TextEditingController(text: formState.churchSlug);
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
            _field('Nome da Sede *', _nameController,
              (v) => notifier.update((s) => s.copyWith(unitName: v)),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            ),
            _field('Slug *', _slugController,
              (v) => notifier.update((s) => s.copyWith(unitSlug: v)),
              hint: 'ex: sede-central',
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            ),
            _field('Telefone *', _phoneController,
              (v) => notifier.update((s) => s.copyWith(unitPhone: v)),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            ),
            _field('E-mail *', _emailController,
              (v) => notifier.update((s) => s.copyWith(unitEmail: v)),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                if (!v.contains('@')) return 'E-mail inválido';
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
    String? Function(String?)? validator,
  }) =>
      Padding(
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
          onChanged: onChanged,
          validator: validator,
        ),
      );
}