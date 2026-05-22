import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:flutter/material.dart';

class AddressFormSection extends StatefulWidget {
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
  State<AddressFormSection> createState() => _AddressFormSectionState();
}

class _AddressFormSectionState extends State<AddressFormSection> {
  late final TextEditingController _zipController;
  late final TextEditingController _countryController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _streetController;
  late final TextEditingController _numberController;
  late final TextEditingController _complementController;
  late final TextEditingController _referenceController;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _zipController = TextEditingController(text: widget.value.zip);
    _countryController = TextEditingController(text: widget.value.country);
    _stateController = TextEditingController(text: widget.value.state);
    _cityController = TextEditingController(text: widget.value.city);
    _neighborhoodController = TextEditingController(
      text: widget.value.neighborhood,
    );
    _streetController = TextEditingController(text: widget.value.street);
    _numberController = TextEditingController(text: widget.value.number);
    _complementController = TextEditingController(
      text: widget.value.complement,
    );
    _referenceController = TextEditingController(text: widget.value.reference);
  }

  @override
  void didUpdateWidget(covariant AddressFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleControllerSync();
  }

  void _scheduleControllerSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncScheduled = false;
      _syncControllers();
    });
  }

  void _syncControllers() {
    _syncController(_zipController, widget.value.zip);
    _syncController(_countryController, widget.value.country);
    _syncController(_stateController, widget.value.state);
    _syncController(_cityController, widget.value.city);
    _syncController(_neighborhoodController, widget.value.neighborhood);
    _syncController(_streetController, widget.value.street);
    _syncController(_numberController, widget.value.number);
    _syncController(_complementController, widget.value.complement);
    _syncController(_referenceController, widget.value.reference);
  }

  @override
  void dispose() {
    _zipController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Text(
              widget.title ?? 'Endereço',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
          ],
          _field(
            label: 'CEP',
            controller: _zipController,
            behavior: AppTextInputBehavior.plain,
            keyboardType: TextInputType.number,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(zip: next)),
          ),
          _field(
            label: 'País',
            controller: _countryController,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(country: next)),
          ),
          _field(
            label: 'Estado',
            controller: _stateController,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(state: next)),
          ),
          _field(
            label: 'Cidade',
            controller: _cityController,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(city: next)),
          ),
          _field(
            label: 'Bairro',
            controller: _neighborhoodController,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(neighborhood: next)),
          ),
          _field(
            label: 'Rua',
            controller: _streetController,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(street: next)),
          ),
          _field(
            label: 'Número',
            controller: _numberController,
            behavior: AppTextInputBehavior.plain,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(number: next)),
          ),
          _field(
            label: 'Complemento',
            controller: _complementController,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(complement: next)),
          ),
          _field(
            label: 'Referência',
            controller: _referenceController,
            onChanged: (next) =>
                widget.onChanged(widget.value.copyWith(reference: next)),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
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

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }
}
