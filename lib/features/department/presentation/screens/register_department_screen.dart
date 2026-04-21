import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/core/utils/slug_utils.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterDepartmentScreen extends ConsumerStatefulWidget {
  const RegisterDepartmentScreen({super.key});

  @override
  ConsumerState<RegisterDepartmentScreen> createState() =>
      _RegisterDepartmentScreenState();
}

class _RegisterDepartmentScreenState
    extends ConsumerState<RegisterDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  String? _selectedType;
  bool _slugEditedManually = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _submit(String unitId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(createDepartmentProvider.notifier)
        .create(
          unitId,
          DepartmentRequestModel(
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            type: _selectedType!,
          ),
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        ref.invalidate(rawDepartmentsProvider(unitId));
        ref.invalidate(filteredDepartmentsProvider(unitId));
        messenger.showSnackBar(
          const SnackBar(content: Text('Departamento cadastrado com sucesso!')),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMembershipAsync = ref.watch(activeMembershipProvider);
    final isLoading = ref.watch(createDepartmentProvider).isLoading;
    final slugPreview = _slugController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cadastrar departamento'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: activeMembershipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _InlineStatus(
          icon: Icons.error_outline,
          title: error is Failure
              ? error.message
              : 'Nao foi possivel carregar a unidade ativa.',
          subtitle: 'Tente novamente em instantes.',
        ),
        data: (membership) {
          final unitId = membership?.unitId;
          if (unitId == null || unitId.isEmpty) {
            return const _InlineStatus(
              icon: Icons.account_tree_outlined,
              title: 'Nenhuma unidade ativa encontrada.',
              subtitle:
                  'Nao foi possivel identificar em qual unidade cadastrar o departamento.',
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const Text(
                  'Novo departamento',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Informe o nome, ajuste o slug se quiser, e escolha o tipo.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Nome *'),
                  onChanged: _handleNameChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obrigatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _slugController,
                  enabled: !isLoading,
                  decoration: _inputDecoration(
                    'Slug *',
                  ).copyWith(hintText: 'ex: louvor-infantil'),
                  textCapitalization:
                      AppTextInputBehavior.lowercaseId.textCapitalization,
                  autocorrect: AppTextInputBehavior.lowercaseId.autocorrect,
                  enableSuggestions:
                      AppTextInputBehavior.lowercaseId.enableSuggestions,
                  onChanged: _handleSlugChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obrigatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    slugPreview.isEmpty
                        ? 'Preview do slug: preencha o nome'
                        : 'Preview do slug: @$slugPreview',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: _inputDecoration('Tipo *'),
                  items: const [
                    DropdownMenuItem(
                      value: 'MINISTRY',
                      child: Text('Departamento'),
                    ),
                    DropdownMenuItem(
                      value: 'ADMINISTRATIVE',
                      child: Text('Administrativo'),
                    ),
                  ],
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() => _selectedType = value);
                        },
                  validator: (value) =>
                      value == null ? 'Campo obrigatorio' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(unitId),
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

  void _handleNameChanged(String value) {
    if (_slugEditedManually) {
      setState(() {});
      return;
    }

    final generatedSlug = slugifyValue(value);
    if (_slugController.text == generatedSlug) {
      setState(() {});
      return;
    }

    _slugController.value = _slugController.value.copyWith(
      text: generatedSlug,
      selection: TextSelection.collapsed(offset: generatedSlug.length),
      composing: TextRange.empty,
    );
    setState(() {});
  }

  void _handleSlugChanged(String value) {
    final normalizedSlug = slugifyValue(value);
    _slugEditedManually = true;

    if (normalizedSlug == value) {
      setState(() {});
      return;
    }

    _slugController.value = _slugController.value.copyWith(
      text: normalizedSlug,
      selection: TextSelection.collapsed(offset: normalizedSlug.length),
      composing: TextRange.empty,
    );
    setState(() {});
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
