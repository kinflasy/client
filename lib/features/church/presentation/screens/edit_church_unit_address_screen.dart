import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/address_form_section.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_general_info_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class EditChurchUnitAddressScreen extends ConsumerStatefulWidget {
  const EditChurchUnitAddressScreen({super.key});

  @override
  ConsumerState<EditChurchUnitAddressScreen> createState() =>
      _EditChurchUnitAddressScreenState();
}

class _EditChurchUnitAddressScreenState
    extends ConsumerState<EditChurchUnitAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formState = ref.read(editChurchUnitAddressFormProvider);
    final profile = await ref.read(currentChurchProfileProvider.future);
    final request =
        buildEditChurchUnitAddressRequest(formState, profile.unit);
    final result = await submitEditChurchUnitAddress(
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
        title: const Text('Endereço da unidade atualizado com sucesso!'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentChurchProfileProvider);
    final formState = ref.watch(editChurchUnitAddressFormProvider);
    final isLoading = ref.watch(editChurchUnitAddressSubmitProvider).isLoading;

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
            initializeEditChurchUnitAddressFormFromProfile(ref, profile);
          });
          return const _ScaffoldFrame(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _ScaffoldFrame(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const _SectionTitle(title: 'Endereço'),
                AbsorbPointer(
                  absorbing: isLoading,
                  child: AddressFormSection(
                    value: formState.address,
                    onChanged: (next) => ref
                        .read(editChurchUnitAddressFormProvider.notifier)
                        .update((state) => state.copyWith(address: next)),
                  ),
                ),
                const SizedBox(height: 16),
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
                        'Editar endereço',
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
        Icon(
          Icons.error_outline,
          size: 48,
          color: AppColors.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
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
