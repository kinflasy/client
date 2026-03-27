import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';

class AddressStep extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  const AddressStep({super.key, required this.formKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(registerChurchFormProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _field('CEP', (v) => notifier.update((s) => s.copyWith(zip: v))),
            _field(
              'País',
              (v) => notifier.update((s) => s.copyWith(country: v)),
            ),
            _field(
              'Estado',
              (v) => notifier.update((s) => s.copyWith(state: v)),
            ),
            _field(
              'Cidade',
              (v) => notifier.update((s) => s.copyWith(city: v)),
            ),
            _field(
              'Bairro',
              (v) => notifier.update((s) => s.copyWith(neighborhood: v)),
            ),
            _field('Rua', (v) => notifier.update((s) => s.copyWith(street: v))),
            _field(
              'Número',
              (v) => notifier.update((s) => s.copyWith(number: v)),
            ),
            _field(
              'Complemento',
              (v) => notifier.update((s) => s.copyWith(complement: v)),
            ),
            _field(
              'Referência',
              (v) => notifier.update((s) => s.copyWith(reference: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, void Function(String) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: onChanged,
    ),
  );
}
