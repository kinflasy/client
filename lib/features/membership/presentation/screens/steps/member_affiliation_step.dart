import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/domain/enums/entry_mode.dart';
import 'package:client/core/presentation/widgets/app_date_text_form_field.dart';
import 'package:client/features/membership/providers/register_member_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberAffiliationStep extends ConsumerStatefulWidget {
  const MemberAffiliationStep({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<MemberAffiliationStep> createState() =>
      _MemberAffiliationStepState();
}

class _MemberAffiliationStepState extends ConsumerState<MemberAffiliationStep> {
  late final TextEditingController _entryDateController;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registerMemberFormProvider);
    _entryDateController = TextEditingController(
      text: formatBrazilianDate(formState.entryDate),
    );
  }

  @override
  void dispose() {
    _entryDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registerMemberFormProvider);
    final notifier = ref.read(registerMemberFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                initialValue: formState.affiliation,
                decoration: _inputDecoration('FiliaÃ§Ã£o *'),
                items: const [
                  DropdownMenuItem(value: 'VISITOR', child: Text('Visitante')),
                  DropdownMenuItem(
                    value: 'CONGREGATED',
                    child: Text('Congregado'),
                  ),
                  DropdownMenuItem(value: 'MEMBER', child: Text('Membro')),
                ],
                onChanged: (value) =>
                    notifier.updateAffiliationData(affiliation: value),
                validator: (value) =>
                    value == null ? 'Campo obrigatÃ³rio' : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<EntryMode>(
                initialValue: formState.entryMode,
                decoration: _inputDecoration('Modo de entrada'),
                items: EntryMode.values
                    .map(
                      (mode) => DropdownMenuItem<EntryMode>(
                        value: mode,
                        child: Text(mode.toLabel()),
                      ),
                    )
                    .toList(),
                onChanged: (value) => notifier.updateAffiliationData(
                  entryMode: value,
                  clearEntryMode: value == null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppDateTextFormField(
                controller: _entryDateController,
                decoration: _inputDecoration('Data de entrada'),
                initialDate: formState.entryDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onPicked: (picked) =>
                    notifier.updateAffiliationData(entryDate: picked),
                onChanged: (value) {
                  final parsed = parseBrazilianDate(value);
                  final isValidPastDate =
                      parsed != null && !parsed.isAfter(DateTime.now());
                  notifier.updateAffiliationData(
                    entryDate: isValidPastDate ? parsed : null,
                    clearEntryDate: !isValidPastDate,
                  );
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final parsed = parseBrazilianDate(value);
                  if (parsed == null) return 'Data inv\u00e1lida';
                  if (parsed.isAfter(DateTime.now())) {
                    return 'Data n\u00e3o pode ser futura';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
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
}
