import 'package:client/core/presentation/widgets/address_form_section.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressStep extends ConsumerWidget {
  final GlobalKey<FormState> formKey;

  const AddressStep({super.key, required this.formKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(registerChurchFormProvider);
    final notifier = ref.watch(registerChurchFormProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: AddressFormSection(
          value: formState.address,
          onChanged: (next) => notifier.update((s) => s.copyWith(address: next)),
        ),
      ),
    );
  }
}
