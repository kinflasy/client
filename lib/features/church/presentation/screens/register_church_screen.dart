import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:client/features/church/data/models/church_request_model.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/church/providers/register_church_form_provider.dart';
import 'steps/church_info_step.dart';
import 'steps/unit_info_step.dart';
import 'steps/address_step.dart';

class RegisterChurchScreen extends ConsumerStatefulWidget {
  const RegisterChurchScreen({super.key});

  @override
  ConsumerState<RegisterChurchScreen> createState() =>
      _RegisterChurchScreenState();
}

class _RegisterChurchScreenState extends ConsumerState<RegisterChurchScreen> {
  int _currentStep = 0;
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  final List<String> _stepTitles = ['Dados da Igreja', 'Sede', 'Endereço'];

  Future<void> _submit() async {
    final formState = ref.read(registerChurchFormProvider);
    final request = ChurchStarterRequestModel(
      name: formState.churchName,
      slug: formState.churchSlug,
      acronym: formState.churchAcronym.isEmpty ? null : formState.churchAcronym,
      phone: formState.churchPhone.isEmpty ? null : formState.churchPhone,
      email: formState.churchEmail,
      unit: UnitRequestModel(
        name: formState.unitName,
        slug: formState.unitSlug,
        phone: formState.unitPhone,
        email: formState.unitEmail,
        address: AddressRequestModel(
          zip: formState.zip.isEmpty ? null : formState.zip,
          country: formState.country.isEmpty ? null : formState.country,
          state: formState.state.isEmpty ? null : formState.state,
          city: formState.city.isEmpty ? null : formState.city,
          neighborhood: formState.neighborhood.isEmpty
              ? null
              : formState.neighborhood,
          street: formState.street.isEmpty ? null : formState.street,
          number: formState.number.isEmpty ? null : formState.number,
          complement: formState.complement.isEmpty
              ? null
              : formState.complement,
          reference: formState.reference.isEmpty ? null : formState.reference,
        ),
      ),
    );

    final result = await ref
        .read(createChurchProvider.notifier)
        .create(request);

    if (!mounted) return;

    result.fold(
      (failure) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(failure.message),
          autoCloseDuration: const Duration(seconds: 4),
        );
      },
      (_) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Igreja cadastrada com sucesso!'),
          autoCloseDuration: const Duration(seconds: 3),
        );
        context.go('/home');
      },
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        return _step2Key.currentState?.validate() ?? false;
      case 2:
        return _step3Key.currentState?.validate() ?? true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createChurchProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_stepTitles[_currentStep]),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, totalSteps: 3),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                ChurchInfoStep(formKey: _step1Key),
                UnitInfoStep(
                  formKey: _step2Key,
                  initialName: ref.read(registerChurchFormProvider).churchName,
                  initialSlug: ref.read(registerChurchFormProvider).churchSlug,
                  initialPhone: ref
                      .read(registerChurchFormProvider)
                      .churchPhone,
                  initialEmail: ref
                      .read(registerChurchFormProvider)
                      .churchEmail,
                ),
                AddressStep(formKey: _step3Key),
              ],
            ),
          ),
          _NavigationButtons(
            currentStep: _currentStep,
            isLoading: isLoading,
            onBack: () => setState(() => _currentStep--),
            onNext: () {
              if (_validateCurrentStep()) {
                setState(() => _currentStep++);
              }
            },
            onSubmit: () {
              if (_validateCurrentStep()) _submit();
            },
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isDone || isActive
                      ? const Color(0xFF1A73E8)
                      : Colors.grey.shade300,
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                ),
                if (i < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? const Color(0xFF1A73E8)
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
  final int currentStep;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _NavigationButtons({
    required this.currentStep,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : currentStep < 2
                  ? onNext
                  : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(currentStep < 2 ? 'Próximo' : 'Confirmar'),
            ),
          ),
        ],
      ),
    );
  }
}
