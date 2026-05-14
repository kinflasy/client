import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:flutter/material.dart';

class AddressFormSection extends StatelessWidget {
  const AddressFormSection({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.padding,
    this.showTitle = false,
  });

  final AddressFormState value;
  final ValueChanged<AddressFormState> onChanged;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              title ?? 'Endereço',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
          ],
          _field(
            label: 'CEP',
            fieldValue: value.zip,
            behavior: AppTextInputBehavior.plain,
            keyboardType: TextInputType.number,
            onChanged: (next) => onChanged(value.copyWith(zip: next)),
          ),
          _field(
            label: 'País',
            fieldValue: value.country,
            onChanged: (next) => onChanged(value.copyWith(country: next)),
          ),
          _field(
            label: 'Estado',
            fieldValue: value.state,
            onChanged: (next) => onChanged(value.copyWith(state: next)),
          ),
          _field(
            label: 'Cidade',
            fieldValue: value.city,
            onChanged: (next) => onChanged(value.copyWith(city: next)),
          ),
          _field(
            label: 'Bairro',
            fieldValue: value.neighborhood,
            onChanged: (next) => onChanged(value.copyWith(neighborhood: next)),
          ),
          _field(
            label: 'Rua',
            fieldValue: value.street,
            onChanged: (next) => onChanged(value.copyWith(street: next)),
          ),
          _field(
            label: 'Número',
            fieldValue: value.number,
            behavior: AppTextInputBehavior.plain,
            onChanged: (next) => onChanged(value.copyWith(number: next)),
          ),
          _field(
            label: 'Complemento',
            fieldValue: value.complement,
            onChanged: (next) => onChanged(value.copyWith(complement: next)),
          ),
          _field(
            label: 'Referência',
            fieldValue: value.reference,
            onChanged: (next) => onChanged(value.copyWith(reference: next)),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String fieldValue,
    required ValueChanged<String> onChanged,
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: fieldValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: keyboardType,
        textCapitalization: behavior.textCapitalization,
        autocorrect: behavior.autocorrect,
        enableSuggestions: behavior.enableSuggestions,
        onChanged: onChanged,
      ),
    );
  }
}
