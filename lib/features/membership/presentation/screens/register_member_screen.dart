import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/data/models/register_member_request_model.dart';
import 'package:client/features/membership/presentation/screens/steps/member_affiliation_step.dart';
import 'package:client/features/membership/presentation/screens/steps/member_personal_data_step.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/membership/providers/register_member_form_provider.dart';
import 'package:client/features/membership/providers/register_member_providers.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class RegisterMemberScreen extends ConsumerStatefulWidget {
  const RegisterMemberScreen({super.key});

  @override
  ConsumerState<RegisterMemberScreen> createState() =>
      _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends ConsumerState<RegisterMemberScreen> {
  int _currentStep = 0;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final List<String> _stepTitles = ['Dados Pessoais', 'VÃ­nculo com a Igreja'];

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        return _step2Key.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;

    final formState = ref.read(registerMemberFormProvider);

    try {
      final membership = await ref.read(activeMembershipProvider.future);
      final unitId = membership?.unitId;

      if (unitId == null || unitId.isEmpty) {
        _showErrorToast();
        return;
      }

      final request = RegisterMemberRequestModel(
        person: InactivePersonRequestModel(
          fullName: formState.fullName.trim(),
          nickname: _nullIfBlank(formState.nickname),
          gender: formState.gender!,
          birthDate: _formatApiDate(formState.birthDate!),
          phone: _nullIfBlank(formState.phone),
          email: _nullIfBlank(formState.email),
        ),
        affiliation: formState.affiliation!,
        entryMode: formState.entryMode?.toApiString(),
        entryDate: formState.entryDate != null
            ? _formatApiDate(formState.entryDate!)
            : null,
      );

      final result = await ref
          .read(registerMemberProvider.notifier)
          .register(unitId, request);

      if (!mounted) return;

      result.fold(
        (_) => _showErrorToast(),
        (_) {
          ref.invalidate(membershipProvider);
          ref.invalidate(activeMembershipProvider);
          ref.invalidate(currentChurchProfileProvider);
          ref.invalidate(rawUnitMembersProvider(unitId));
          ref.invalidate(registerMemberFormProvider);
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Membro cadastrado com sucesso!'),
            autoCloseDuration: const Duration(seconds: 3),
          );
          context.pop();
        },
      );
    } catch (_) {
      if (!mounted) return;
      _showErrorToast();
    }
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showErrorToast() {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: const Text('NÃ£o foi possÃ­vel cadastrar o membro.'),
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(registerMemberProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_stepTitles[_currentStep]),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, totalSteps: 2),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                MemberPersonalDataStep(formKey: _step1Key),
                MemberAffiliationStep(formKey: _step2Key),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _NavigationButtons(
        currentStep: _currentStep,
        totalSteps: 2,
        isLoading: isLoading,
        onBack: () => setState(() => _currentStep--),
        onNext: () {
          if (_validateCurrentStep()) {
            setState(() => _currentStep++);
          }
        },
        onConfirm: _submit,
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index == currentStep;
          final isDone = index < currentStep;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isDone || isActive
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                ),
                if (index < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({
    required this.currentStep,
    required this.totalSteps,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
    required this.onConfirm,
  });

  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onBack,
                child: const Text('Voltar'),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : isLastStep
                  ? onConfirm
                  : onNext,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isLastStep ? 'Confirmar' : 'PrÃ³ximo'),
            ),
          ),
        ],
      ),
    );
  }
}
