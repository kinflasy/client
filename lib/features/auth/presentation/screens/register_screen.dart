import 'package:client/core/presentation/forms/app_autofill_hints.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/presentation/forms/app_text_input_behavior.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  String? _selectedGender;
  DateTime? _birthDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _showWarning('Preencha todos os campos obrigat\u00f3rios');
      return false;
    }
    if (!email.contains('@')) {
      _showWarning('Informe um e-mail v\u00e1lido');
      return false;
    }
    if (password.length < 6) {
      _showWarning('A senha deve ter pelo menos 6 caracteres');
      return false;
    }
    if (password != confirm) {
      _showWarning('As senhas n\u00e3o coincidem');
      return false;
    }
    if (_selectedGender == null) {
      _showWarning('Selecione o g\u00eanero');
      return false;
    }

    final parsedBirthDate = parseBrazilianDate(_birthDateController.text);
    if (parsedBirthDate == null) {
      _showWarning('Informe uma data de nascimento v\u00e1lida');
      return false;
    }
    if (parsedBirthDate.isAfter(_today())) {
      _showWarning('A data de nascimento n\u00e3o pode ser futura');
      return false;
    }

    _birthDate = parsedBirthDate;
    return true;
  }

  void _showWarning(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    await ref
        .read(authProvider.notifier)
        .signUp(
          name: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          gender: _selectedGender!,
          birthDate: _birthDate!,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(authState.error.toString()),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(_today().year - 18, 1, 1),
      firstDate: DateTime(1900),
      lastDate: _today(),
    );
    if (picked == null) return;

    setState(() {
      _birthDate = picked;
      _birthDateController.text = formatBrazilianDate(picked);
    });
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Criar conta',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha seus dados para se cadastrar',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textCapitalization:
                    AppTextInputBehavior.nameLike.textCapitalization,
                autocorrect: AppTextInputBehavior.nameLike.autocorrect,
                enableSuggestions:
                    AppTextInputBehavior.nameLike.enableSuggestions,
                autofillHints: AppAutofillHints.fullName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usu\u00e1rio *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization:
                    AppTextInputBehavior.lowercaseId.textCapitalization,
                autocorrect: AppTextInputBehavior.lowercaseId.autocorrect,
                enableSuggestions:
                    AppTextInputBehavior.lowercaseId.enableSuggestions,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textCapitalization:
                    AppTextInputBehavior.emailLike.textCapitalization,
                autocorrect: AppTextInputBehavior.emailLike.autocorrect,
                enableSuggestions:
                    AppTextInputBehavior.emailLike.enableSuggestions,
                autofillHints: AppAutofillHints.email,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'G\u00eanero *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Masculino')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Feminino')),
                ],
                onChanged: isLoading
                    ? null
                    : (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Data de nascimento *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.cake_outlined),
                  hintText: 'DD/MM/AAAA',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: isLoading ? null : _pickBirthDate,
                  ),
                ),
                keyboardType: TextInputType.datetime,
                autofillHints: AppAutofillHints.birthDate,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  const DateTextInputFormatter(),
                ],
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  final parsedBirthDate = parseBrazilianDate(value);
                  _birthDate =
                      parsedBirthDate != null &&
                          !parsedBirthDate.isAfter(_today())
                      ? parsedBirthDate
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cadastrar'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('J\u00e1 tem conta? Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
