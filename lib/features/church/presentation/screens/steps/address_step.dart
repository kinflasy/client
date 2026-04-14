import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            _field(
              'CEP',
              (v) => notifier.update((s) => s.copyWith(zip: v)),
              behavior: AppTextInputBehavior.plain,
            ),
            _field(
              'Pa\u00eds',
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
              'N\u00famero',
              (v) => notifier.update((s) => s.copyWith(number: v)),
              behavior: AppTextInputBehavior.plain,
            ),
            _field(
              'Complemento',
              (v) => notifier.update((s) => s.copyWith(complement: v)),
            ),
            _field(
              'Refer\u00eancia',
              (v) => notifier.update((s) => s.copyWith(reference: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    void Function(String) onChanged, {
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        textCapitalization: behavior.textCapitalization,
        autocorrect: behavior.autocorrect,
        enableSuggestions: behavior.enableSuggestions,
        onChanged: onChanged,
      ),
    );
  }
}
