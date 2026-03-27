import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';

class UnitInfoStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final String? initialName;
  final String? initialSlug;
  final String? initialPhone;
  final String? initialEmail;

  const UnitInfoStep({
    super.key,
    required this.formKey,
    this.initialName,
    this.initialSlug,
    this.initialPhone,
    this.initialEmail,
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
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _slugController = TextEditingController(text: widget.initialSlug ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');

    // Pré-popula o estado do formulário com os valores iniciais
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(registerChurchFormProvider.notifier);
      if (widget.initialName != null) {
        notifier.update((s) => s.copyWith(unitName: widget.initialName));
      }
      if (widget.initialSlug != null) {
        notifier.update((s) => s.copyWith(unitSlug: widget.initialSlug));
      }
      if (widget.initialPhone != null) {
        notifier.update((s) => s.copyWith(unitPhone: widget.initialPhone));
      }
      if (widget.initialEmail != null) {
        notifier.update((s) => s.copyWith(unitEmail: widget.initialEmail));
      }
    });
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