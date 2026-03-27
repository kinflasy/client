import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';

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
            _field('Nome da Igreja *',
              (v) => notifier.update((s) => s.copyWith(churchName: v)),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            ),
            _field('Slug *',
              (v) => notifier.update((s) => s.copyWith(churchSlug: v)),
              hint: 'ex: minha-igreja',
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            ),
            _field('Sigla',
              (v) => notifier.update((s) => s.copyWith(churchAcronym: v)),
            ),
            _field('Telefone',
              (v) => notifier.update((s) => s.copyWith(churchPhone: v)),
              keyboardType: TextInputType.phone,
            ),
            _field('E-mail *',
              (v) => notifier.update((s) => s.copyWith(churchEmail: v)),
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
    void Function(String) onChanged, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      Padding(
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
          onChanged: onChanged,
          validator: validator,
        ),
      );
}