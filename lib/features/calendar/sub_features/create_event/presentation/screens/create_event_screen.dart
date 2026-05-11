import 'dart:io';

import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/core/presentation/widgets/app_date_text_form_field.dart';
import 'package:client/core/presentation/widgets/app_time_text_form_field.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/sub_features/create_event/presentation/widgets/visibility_rules_selector.dart';
import 'package:client/features/calendar/sub_features/create_event/providers/create_event_providers.dart';
import 'package:client/features/calendar/sub_features/create_event/providers/event_image_picker_provider.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _EventOwnerScope { unit, department }

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endDateController = TextEditingController();
  final _endTimeController = TextEditingController();

  _EventOwnerScope _ownerScope = _EventOwnerScope.unit;
  String? _selectedDepartmentId;
  List<VisibilityRuleEntity> _visibilityRules = const [];
  PickedEventImage? _pickedImage;
  String? _dateTimeError;
  bool _endDateWasAutoFilled = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ref.read(eventImagePickerProvider).pickImage();
    if (image == null) return;

    final validationMessage = validatePickedEventImage(image);
    if (validationMessage != null) {
      _showSnack(validationMessage);
      return;
    }

    setState(() => _pickedImage = image);
  }

  Future<void> _submit(String unitId) async {
    setState(() {
      _dateTimeError = _validateDateRange();
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dateTimeError != null) return;

    final start = _combineDateTime(
      _startDateController.text,
      _startTimeController.text,
    );
    final end = _combineDateTime(
      _endDateController.text,
      _endTimeController.text,
    );
    if (start == null || end == null) return;

    final request = CalendarEventRequestModel(
      title: _titleController.text.trim(),
      description: _nullableTrim(_descriptionController.text),
      startDateTime: start,
      endDateTime: end,
      visibilityRules: _effectiveVisibilityRules(),
    );

    final notifier = ref.read(createCalendarEventProvider.notifier);
    final result = _ownerScope == _EventOwnerScope.unit
        ? await notifier.createUnitEvent(
            unitId,
            request,
            cardImagePath: _pickedImage?.path,
          )
        : await notifier.createDepartmentEvent(
            _selectedDepartmentId!,
            request,
            cardImagePath: _pickedImage?.path,
          );

    if (!mounted) return;

    result.fold((failure) => _showSnack(failure.message), (_) {
      _showSnack('Evento criado com sucesso.');
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentChurchProfileProvider);
    final isLoading = ref.watch(createCalendarEventProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Criar evento'),
        backgroundColor: AppColors.surface,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _InlineStatus(
          icon: Icons.error_outline,
          title: error is Failure
              ? error.message
              : 'Não foi possível carregar a unidade ativa.',
          subtitle: 'Tente novamente em instantes.',
        ),
        data: (profile) {
          final unitId = profile.unit.id;
          final departmentsAsync = ref.watch(departmentsProvider(unitId));

          return departmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _InlineStatus(
              icon: Icons.error_outline,
              title: error is Failure
                  ? error.message
                  : 'Não foi possível carregar os departamentos.',
              subtitle: 'Tente novamente em instantes.',
            ),
            data: (departments) {
              if (_selectedDepartmentId == null && departments.isNotEmpty) {
                _selectedDepartmentId = departments.first.id;
              }

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration('Título *'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isLoading,
                      maxLines: 4,
                      textCapitalization:
                          AppTextInputBehavior.plain.textCapitalization,
                      autocorrect: AppTextInputBehavior.plain.autocorrect,
                      enableSuggestions:
                          AppTextInputBehavior.plain.enableSuggestions,
                      decoration: _inputDecoration('Descrição'),
                    ),
                    const SizedBox(height: 16),
                    _DateTimeFields(
                      startDateController: _startDateController,
                      startTimeController: _startTimeController,
                      endDateController: _endDateController,
                      endTimeController: _endTimeController,
                      enabled: !isLoading,
                      dateTimeError: _dateTimeError,
                      onStartDateChanged: _handleStartDateChanged,
                      onStartTimeChanged: _handleStartTimeChanged,
                      onEndDateChanged: _handleEndDateChanged,
                    ),
                    if (_dateTimeError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _dateTimeError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<_EventOwnerScope>(
                      initialValue: _ownerScope,
                      decoration: _inputDecoration('Organizado por *'),
                      items: const [
                        DropdownMenuItem(
                          value: _EventOwnerScope.unit,
                          child: Text('Unidade'),
                        ),
                        DropdownMenuItem(
                          value: _EventOwnerScope.department,
                          child: Text('Departamento'),
                        ),
                      ],
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _ownerScope = value);
                            },
                    ),
                    if (_ownerScope == _EventOwnerScope.department) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDepartmentId,
                        decoration: _inputDecoration('Departamento *'),
                        items: departments
                            .map(
                              (department) => DropdownMenuItem(
                                value: department.id,
                                child: Text(department.name),
                              ),
                            )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) =>
                                  setState(() => _selectedDepartmentId = value),
                        validator: (value) =>
                            _ownerScope == _EventOwnerScope.department &&
                                (value == null || value.isEmpty)
                            ? 'Campo obrigatório'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    VisibilityRulesSelector(
                      unitId: unitId,
                      departments: departments,
                      rules: _visibilityRules,
                      onChanged: isLoading
                          ? (_) {}
                          : (rules) => setState(() {
                              _visibilityRules = rules;
                            }),
                    ),
                    const SizedBox(height: 20),
                    _EventImageSection(
                      image: _pickedImage,
                      isLoading: isLoading,
                      onChange: _pickImage,
                      onRemove: () => setState(() => _pickedImage = null),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      key: const Key('save-event-button'),
                      onPressed: isLoading ? null : () => _submit(unitId),
                      icon: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Salvar evento'),
                    ),
                  ],
                ),
              );
            },
          );
        },
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

  DateTime? _combineDateTime(String dateText, String timeText) {
    final date = parseBrazilianDate(dateText);
    final time = parseBrazilianTime(timeText);
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  List<VisibilityRuleEntity> _effectiveVisibilityRules() {
    return _visibilityRules.isEmpty
        ? const [VisibilityRuleEntity.user(userId: '*')]
        : _visibilityRules;
  }

  void _handleStartDateChanged(String value) {
    if (_endDateController.text.trim().isNotEmpty) return;

    final startDate = parseBrazilianDate(value);
    if (startDate == null) return;

    _endDateController.text = formatBrazilianDate(startDate);
    _endDateWasAutoFilled = true;
  }

  void _handleStartTimeChanged(String value) {
    if (_endTimeController.text.trim().isNotEmpty) return;

    final startTime = parseBrazilianTime(value);
    if (startTime == null) return;

    final startDate =
        parseBrazilianDate(_startDateController.text) ?? DateTime(2000);
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = startDateTime.add(const Duration(hours: 2));

    _endTimeController.text = formatBrazilianTime(
      TimeOfDay.fromDateTime(endDateTime),
    );

    final shouldAdjustEndDate =
        _endDateController.text.trim().isEmpty || _endDateWasAutoFilled;
    if (shouldAdjustEndDate) {
      _endDateController.text = formatBrazilianDate(endDateTime);
      _endDateWasAutoFilled = true;
    }
  }

  void _handleEndDateChanged(String value) {
    if (value.trim().isNotEmpty) {
      _endDateWasAutoFilled = false;
    }
  }

  String? _validateDateRange() {
    final startDate = _startDateController.text.trim();
    final startTime = _startTimeController.text.trim();
    final endDate = _endDateController.text.trim();
    final endTime = _endTimeController.text.trim();

    if (startDate.isEmpty ||
        startTime.isEmpty ||
        endDate.isEmpty ||
        endTime.isEmpty) {
      return null;
    }

    final start = _combineDateTime(startDate, startTime);
    final end = _combineDateTime(endDate, endTime);
    if (start == null || end == null) {
      return 'Informe datas e horários válidos.';
    }
    if (!end.isAfter(start)) return 'O fim deve ser posterior ao início.';
    return null;
  }

  String? _nullableTrim(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DateTimeFields extends StatelessWidget {
  const _DateTimeFields({
    required this.startDateController,
    required this.startTimeController,
    required this.endDateController,
    required this.endTimeController,
    required this.enabled,
    required this.dateTimeError,
    required this.onStartDateChanged,
    required this.onStartTimeChanged,
    required this.onEndDateChanged,
  });

  final TextEditingController startDateController;
  final TextEditingController startTimeController;
  final TextEditingController endDateController;
  final TextEditingController endTimeController;
  final bool enabled;
  final String? dateTimeError;
  final ValueChanged<String> onStartDateChanged;
  final ValueChanged<String> onStartTimeChanged;
  final ValueChanged<String> onEndDateChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppDateTextFormField(
                key: const Key('start-date-field'),
                controller: startDateController,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'Data de início *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: onStartDateChanged,
                validator: _requiredDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTimeTextFormField(
                key: const Key('start-time-field'),
                controller: startTimeController,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'Hora de início *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: onStartTimeChanged,
                validator: _requiredTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppDateTextFormField(
                key: const Key('end-date-field'),
                controller: endDateController,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'Data de fim *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: onEndDateChanged,
                validator: _requiredDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTimeTextFormField(
                key: const Key('end-time-field'),
                controller: endTimeController,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'Hora de fim *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => dateTimeError ?? _requiredTime(value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _requiredDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return parseBrazilianDate(value) == null ? 'Data inválida' : null;
  }

  String? _requiredTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return parseBrazilianTime(value) == null ? 'Hora inválida' : null;
  }
}

class _EventImageSection extends StatelessWidget {
  const _EventImageSection({
    required this.image,
    required this.isLoading,
    required this.onChange,
    required this.onRemove,
  });

  final PickedEventImage? image;
  final bool isLoading;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Imagem do evento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Opcional. A imagem será enviada depois que o evento for criado.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(image!.path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: Text(image!.name),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isLoading ? null : onChange,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  image == null ? 'Selecionar imagem' : 'Alterar imagem',
                ),
              ),
              if (image != null)
                OutlinedButton.icon(
                  onPressed: isLoading ? null : onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover imagem'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
