import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/core/presentation/widgets/app_email_text_form_field.dart';
import 'package:client/core/presentation/widgets/app_phone_text_form_field.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_general_info_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class EditChurchUnitIdentityScreen extends ConsumerStatefulWidget {
  const EditChurchUnitIdentityScreen({super.key});

  @override
  ConsumerState<EditChurchUnitIdentityScreen> createState() =>
      _EditChurchUnitIdentityScreenState();
}

class _EditChurchUnitIdentityScreenState
    extends ConsumerState<EditChurchUnitIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _controllersSeeded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _slugController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formState = ref.read(editChurchUnitIdentityFormProvider);
    final profile = await ref.read(currentChurchProfileProvider.future);
    final request = buildEditChurchUnitIdentityRequest(formState, profile.unit);
    final result = await submitEditChurchUnitIdentity(
      ref,
      request: request,
      currentUnit: profile.unit,
    );

    if (!mounted) return;

    await result.match((failure) async => _showErrorToast(failure.message), (
      _,
    ) async {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Identidade da unidade atualizada com sucesso!'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentChurchProfileProvider);
    final formState = ref.watch(editChurchUnitIdentityFormProvider);
    final isLoading = ref.watch(editChurchUnitIdentitySubmitProvider).isLoading;

    return profileAsync.when(
      loading: () => const _ScaffoldFrame(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ScaffoldFrame(
        child: _LoadError(
          message: error is Failure
              ? error.message
              : 'Não foi possível carregar os dados da unidade.',
          onRetry: () => ref.invalidate(currentChurchProfileProvider),
        ),
      ),
      data: (profile) {
        if (!formState.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            initializeEditChurchUnitIdentityFormFromProfile(ref, profile);
          });
          return const _ScaffoldFrame(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        _seedControllersIfNeeded(formState);

        return _ScaffoldFrame(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const _SectionTitle(title: 'Identidade'),
                _field(
                  controller: _nameController,
                  label: 'Nome da unidade *',
                  enabled: !isLoading,
                  onChanged: (value) => ref
                      .read(editChurchUnitIdentityFormProvider.notifier)
                      .update((state) => state.copyWith(name: value)),
                  validator: _requiredValidator,
                ),
                _field(
                  controller: _slugController,
                  label: 'Slug *',
                  behavior: AppTextInputBehavior.plain,
                  enabled: !isLoading,
                  onChanged: (value) => ref
                      .read(editChurchUnitIdentityFormProvider.notifier)
                      .update((state) => state.copyWith(slug: value)),
                  validator: _requiredValidator,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppPhoneTextFormField(
                    controller: _phoneController,
                    decoration: _inputDecoration(
                      'Telefone *',
                    ).copyWith(hintText: '(00) 00000-0000'),
                    enabled: !isLoading,
                    onChanged: (value) => ref
                        .read(editChurchUnitIdentityFormProvider.notifier)
                        .update((state) => state.copyWith(phone: value)),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo obrigatório';
                      }
                      return isCompleteBrazilianPhone(value)
                          ? null
                          : 'Telefone inválido';
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppEmailTextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('E-mail *'),
                    enabled: !isLoading,
                    onChanged: (value) => ref
                        .read(editChurchUnitIdentityFormProvider.notifier)
                        .update((state) => state.copyWith(email: value)),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      return emailRegex.hasMatch(value.trim())
                          ? null
                          : 'E-mail inválido';
                    },
                  ),
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
      },
    );
  }

  void _seedControllersIfNeeded(EditChurchUnitIdentityFormState formState) {
    if (!formState.isInitialized || _controllersSeeded) return;
    _setControllerValue(_nameController, formState.name);
    _setControllerValue(_slugController, formState.slug);
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  InputDecoration _inputDecoration(String label) {
    return const InputDecoration(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ).copyWith(labelText: label);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    AppTextInputBehavior behavior = AppTextInputBehavior.nameLike,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        textCapitalization: behavior.textCapitalization,
        autocorrect: behavior.autocorrect,
        enableSuggestions: behavior.enableSuggestions,
        enabled: enabled,
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
  const _ScaffoldFrame({required this.child});

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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Editar identidade',
                        style: TextStyle(
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}
