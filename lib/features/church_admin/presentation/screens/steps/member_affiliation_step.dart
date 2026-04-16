import 'package:client/core/domain/enums/entry_mode.dart';
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
      text: _formatDate(formState.entryDate),
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

    final formattedEntryDate = _formatDate(formState.entryDate);
    if (_entryDateController.text != formattedEntryDate) {
      _entryDateController.text = formattedEntryDate;
    }

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
                decoration: _inputDecoration('Filiação *'),
                items: const [
                  DropdownMenuItem(
                    value: 'VISITOR',
                    child: Text('Visitante'),
                  ),
                  DropdownMenuItem(
                    value: 'CONGREGATED',
                    child: Text('Congregado'),
                  ),
                  DropdownMenuItem(
                    value: 'MEMBER',
                    child: Text('Membro'),
                  ),
                ],
                onChanged: (value) =>
                    notifier.updateAffiliationData(affiliation: value),
                validator: (value) =>
                    value == null ? 'Campo obrigatório' : null,
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
              child: TextFormField(
                controller: _entryDateController,
                readOnly: true,
                decoration: _inputDecoration('Data de entrada').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: formState.entryDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        notifier.updateAffiliationData(entryDate: picked);
                      }
                    },
                  ),
                ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
