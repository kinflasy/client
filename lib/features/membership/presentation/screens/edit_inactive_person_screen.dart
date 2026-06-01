import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/core/presentation/widgets/app_date_text_form_field.dart';
import 'package:client/core/presentation/widgets/app_email_text_form_field.dart';
import 'package:client/core/presentation/widgets/app_phone_text_form_field.dart';
import 'package:client/core/presentation/widgets/address_form_section.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/providers/edit_inactive_person_providers.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class EditInactivePersonScreen extends ConsumerStatefulWidget {
  const EditInactivePersonScreen({
    super.key,
    required this.personId,
    this.initialProfile,
  });

  final String personId;
  final MemberProfileEntity? initialProfile;

  @override
  ConsumerState<EditInactivePersonScreen> createState() =>
      _EditInactivePersonScreenState();
}

class _EditInactivePersonScreenState
    extends ConsumerState<EditInactivePersonScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _controllersSeeded = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _nicknameController = TextEditingController();
    _birthDateController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    final initialProfile = widget.initialProfile;
    if (initialProfile != null) {
      Future<void>.microtask(() {
        if (!mounted) return;
        initializeEditInactivePersonForm(
          ref,
          personId: widget.personId,
          profile: initialProfile,
        );
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formState = ref.read(editInactivePersonFormProvider(widget.personId));
    final request = buildUpdateInactivePersonRequest(formState);
    final result = await submitEditInactivePerson(
      ref,
      personId: widget.personId,
      request: request,
    );

    if (!mounted) return;

    await result.match(
      (failure) async {
        _showErrorToast(failure.message);
      },
      (_) async {
        await invalidateInactivePersonEditDependencies(
          ref,
          personId: widget.personId,
        );
        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Cadastro atualizado com sucesso!'),
          autoCloseDuration: const Duration(seconds: 3),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(
      editInactivePersonFormProvider(widget.personId),
    );
    final isLoading = ref.watch(editInactivePersonSubmitProvider).isLoading;
    final profileAsync = widget.initialProfile == null
        ? ref.watch(memberProfileProvider(widget.personId))
        : null;

    if (!formState.isInitialized && profileAsync != null) {
      return profileAsync.when(
        loading: () => _ScaffoldFrame(
          title: 'Editar cadastro',
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _ScaffoldFrame(
          title: 'Editar cadastro',
          child: _LoadError(
            message: error is Failure
                ? error.message
                : 'Não foi possível carregar os dados para edição.',
            onRetry: () =>
                ref.invalidate(memberProfileProvider(widget.personId)),
          ),
        ),
        data: (profile) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            initializeEditInactivePersonForm(
              ref,
              personId: widget.personId,
              profile: profile,
            );
          });
          return _ScaffoldFrame(
            title: 'Editar cadastro',
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    _seedControllersIfNeeded(formState);

    return _ScaffoldFrame(
      title: 'Editar cadastro',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _SectionTitle(title: 'Dados pessoais'),
            _field(
              controller: _fullNameController,
              label: 'Nome completo *',
              onChanged: (value) => updateEditInactivePersonPersonalData(
                ref,
                personId: widget.personId,
                fullName: value,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obrigatorio';
                }
                return null;
              },
            ),
            _field(
              controller: _nicknameController,
              label: 'Apelido',
              onChanged: (value) => updateEditInactivePersonPersonalData(
                ref,
                personId: widget.personId,
                nickname: value,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                initialValue: formState.gender,
                decoration: _inputDecoration('Genero *'),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Masculino')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Feminino')),
                ],
                onChanged: (value) => updateEditInactivePersonPersonalData(
                  ref,
                  personId: widget.personId,
                  gender: value,
                ),
                validator: (value) =>
                    value == null ? 'Campo obrigatorio' : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppDateTextFormField(
                controller: _birthDateController,
                decoration: _inputDecoration('Data de nascimento *'),
                enabled: !isLoading,
                initialDate:
                    formState.birthDate ?? DateTime(DateTime.now().year - 18),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onPicked: (picked) => updateEditInactivePersonPersonalData(
                  ref,
                  personId: widget.personId,
                  birthDate: picked,
                ),
                onChanged: (value) {
                  final parsed = parseBrazilianDate(value);
                  final isValidPastDate =
                      parsed != null && !parsed.isAfter(DateTime.now());
                  updateEditInactivePersonPersonalData(
                    ref,
                    personId: widget.personId,
                    birthDate: isValidPastDate ? parsed : null,
                    clearBirthDate: !isValidPastDate,
                  );
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatorio';
                  }
                  final parsed = parseBrazilianDate(value);
                  if (parsed == null) return 'Data invalida';
                  if (parsed.isAfter(DateTime.now())) {
                    return 'Data nao pode ser futura';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppPhoneTextFormField(
                controller: _phoneController,
                decoration: _inputDecoration(
                  'Telefone',
                ).copyWith(hintText: '(00) 00000-0000'),
                onChanged: (value) => updateEditInactivePersonPersonalData(
                  ref,
                  personId: widget.personId,
                  phone: value,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return isCompleteBrazilianPhone(value)
                      ? null
                      : 'Telefone invalido';
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppEmailTextFormField(
                controller: _emailController,
                decoration: _inputDecoration('E-mail'),
                onChanged: (value) => updateEditInactivePersonPersonalData(
                  ref,
                  personId: widget.personId,
                  email: value,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  return emailRegex.hasMatch(value.trim())
                      ? null
                      : 'E-mail invalido';
                },
              ),
            ),
            const SizedBox(height: 8),
            _SectionTitle(title: 'Endereco'),
            AddressFormSection(
              value: formState.address,
              onChanged: (next) => ref
                  .read(
                    editInactivePersonFormProvider(widget.personId).notifier,
                  )
                  .update((state) => state.copyWith(address: next)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _seedControllersIfNeeded(EditInactivePersonFormState formState) {
    if (!formState.isInitialized || _controllersSeeded) return;
    _setControllerValue(_fullNameController, formState.fullName);
    _setControllerValue(_nicknameController, formState.nickname);
    _setControllerValue(
      _birthDateController,
      formatBrazilianDate(formState.birthDate),
    );
    _setControllerValue(
      _phoneController,
      formatBrazilianPhone(formState.phone),
    );
    _setControllerValue(_emailController, formState.email);
    _controllersSeeded = true;
  }

  void _setControllerValue(TextEditingController controller, String value) {
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        textCapitalization: behavior.textCapitalization,
        autocorrect: behavior.autocorrect,
        enableSuggestions: behavior.enableSuggestions,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 4),
    );
  }
}

class _ScaffoldFrame extends StatelessWidget {
  const _ScaffoldFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 56),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
            const ChurchFloatingBackButton(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
