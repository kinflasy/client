import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/activation_user_entity.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:client/features/membership/providers/activate_member_providers.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class ActivateMemberScreen extends ConsumerStatefulWidget {
  const ActivateMemberScreen({super.key, this.initialProfile});

  final MemberProfileEntity? initialProfile;

  @override
  ConsumerState<ActivateMemberScreen> createState() =>
      _ActivateMemberScreenState();
}

class _ActivateMemberScreenState extends ConsumerState<ActivateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  UnitMemberEntity? _selectedPerson;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _syncInitialPerson(List<UnitMemberEntity> inactivePeople) {
    if (_selectedPerson != null || widget.initialProfile == null) return;

    final personId = widget.initialProfile!.personId;
    for (final person in inactivePeople) {
      if (person.personId == personId) {
        _selectedPerson = person;
        return;
      }
    }

    final profile = widget.initialProfile!;
    _selectedPerson = UnitMemberEntity(
      membershipId: profile.membershipId,
      personId: profile.personId,
      personType: PersonType.inactive,
      fullName: profile.fullName,
      nickname: profile.nickname,
      affiliation: profile.affiliation,
      gender: profile.gender,
      profileImageId: profile.profileImageId,
    );
  }

  Future<void> _searchUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(userByUsernameLookupProvider.notifier)
        .search(_usernameController.text);
  }

  Future<void> _submit(ActivationUserEntity user) async {
    final selectedPerson = _selectedPerson;
    if (selectedPerson == null) {
      _showErrorToast('Selecione uma pessoa inativa.');
      return;
    }

    final result = await ref
        .read(activateMemberProvider.notifier)
        .activate(
          inactivePersonId: selectedPerson.personId,
          username: user.username,
        );

    if (!mounted) return;

    result.fold((failure) => _showErrorToast(failure.message), (_) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Usuário vinculado com sucesso!'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      context.pop();
    });
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMembershipAsync = ref.watch(activeMembershipProvider);
    final lookupState = ref.watch(userByUsernameLookupProvider);
    final submitState = ref.watch(activateMemberProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vincular usuário Pontis'),
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
              : 'Não foi possível carregar a unidade ativa.',
        ),
        data: (membership) {
          final unitId = membership?.unitId;
          if (unitId == null || unitId.isEmpty) {
            return const _InlineStatus(
              icon: Icons.people_outline,
              title: 'Nenhuma unidade ativa encontrada.',
            );
          }

          final membersAsync = ref.watch(rawUnitMembersProvider(unitId));
          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _InlineStatus(
              icon: Icons.group_off_outlined,
              title: error is Failure
                  ? error.message
                  : 'Não foi possível carregar as pessoas vinculadas.',
            ),
            data: (members) {
              final inactivePeople =
                  members
                      .where(
                        (member) => member.personType == PersonType.inactive,
                      )
                      .toList()
                    ..sort((a, b) => a.fullName.compareTo(b.fullName));
              _syncInitialPerson(inactivePeople);

              return _ActivationForm(
                formKey: _formKey,
                usernameController: _usernameController,
                inactivePeople: inactivePeople,
                selectedPerson: _selectedPerson,
                lookupState: lookupState,
                submitState: submitState,
                onSelectPerson: (person) {
                  setState(() => _selectedPerson = person);
                },
                onUsernameChanged: (_) {
                  ref.read(userByUsernameLookupProvider.notifier).clear();
                },
                onSearchUser: _searchUser,
                onSubmit: _submit,
              );
            },
          );
        },
      ),
    );
  }
}

class _ActivationForm extends StatelessWidget {
  const _ActivationForm({
    required this.formKey,
    required this.usernameController,
    required this.inactivePeople,
    required this.selectedPerson,
    required this.lookupState,
    required this.submitState,
    required this.onSelectPerson,
    required this.onUsernameChanged,
    required this.onSearchUser,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final List<UnitMemberEntity> inactivePeople;
  final UnitMemberEntity? selectedPerson;
  final AsyncValue<ActivationUserEntity?> lookupState;
  final AsyncValue<void> submitState;
  final ValueChanged<UnitMemberEntity?> onSelectPerson;
  final ValueChanged<String> onUsernameChanged;
  final VoidCallback onSearchUser;
  final ValueChanged<ActivationUserEntity> onSubmit;

  @override
  Widget build(BuildContext context) {
    final isSearching = lookupState.isLoading;
    final isSubmitting = submitState.isLoading;
    final user = lookupState.asData?.value;
    final canSubmit =
        selectedPerson != null && user != null && !isSearching && !isSubmitting;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          DropdownButtonFormField<UnitMemberEntity>(
            initialValue: selectedPerson,
            decoration: _inputDecoration(
              label: 'Pessoa inativa',
              icon: Icons.person_outline,
            ),
            items: inactivePeople
                .map(
                  (person) => DropdownMenuItem<UnitMemberEntity>(
                    value: person,
                    child: Text(_personLabel(person)),
                  ),
                )
                .toList(),
            onChanged: isSubmitting ? null : onSelectPerson,
            validator: (value) =>
                value == null ? 'Selecione uma pessoa inativa' : null,
          ),
          if (inactivePeople.isEmpty) ...[
            const SizedBox(height: 12),
            const _InlineStatus(
              icon: Icons.person_off_outlined,
              title: 'Nenhuma pessoa inativa encontrada.',
              subtitle: 'Cadastre uma pessoa sem conta antes de vincular.',
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: usernameController,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.search,
            decoration: _inputDecoration(
              label: 'Usuário Pontis',
              hint: '@usuario',
              icon: Icons.alternate_email,
              suffix: IconButton(
                onPressed: isSearching || isSubmitting ? null : onSearchUser,
                icon: isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                tooltip: 'Buscar usuário',
              ),
            ),
            onChanged: onUsernameChanged,
            onFieldSubmitted: (_) => onSearchUser(),
            validator: (value) {
              final normalized = value?.trim().replaceFirst(RegExp(r'^@+'), '');
              if (normalized == null || normalized.isEmpty) {
                return 'Informe o usuário';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          lookupState.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => _InlineStatus(
              icon: Icons.search_off_outlined,
              title: error is Failure
                  ? error.message
                  : 'Não foi possível buscar o usuário.',
            ),
            data: (foundUser) => foundUser == null
                ? const SizedBox.shrink()
                : _UserPreview(user: foundUser),
          ),
          if (selectedPerson != null && user != null) ...[
            const SizedBox(height: 16),
            _ConfirmationPreview(person: selectedPerson!, user: user),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: canSubmit ? () => onSubmit(user) : null,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.link),
            label: const Text('Vincular usuário'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  String _personLabel(UnitMemberEntity person) {
    final nickname = person.nickname?.trim();
    if (nickname == null || nickname.isEmpty) return person.fullName;
    return '${person.fullName} ($nickname)';
  }
}

class _UserPreview extends StatelessWidget {
  const _UserPreview({required this.user});

  final ActivationUserEntity user;

  @override
  Widget build(BuildContext context) {
    return _SummaryTile(
      icon: Icons.check_circle_outline,
      title: '@${user.username}',
      subtitle: _hasText(user.nickname) ? user.nickname! : 'Usuário encontrado',
      profileImageId: user.profileImageId,
    );
  }
}

class _ConfirmationPreview extends StatelessWidget {
  const _ConfirmationPreview({required this.person, required this.user});

  final UnitMemberEntity person;
  final ActivationUserEntity user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmação',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            icon: Icons.person_outline,
            title: person.fullName,
            subtitle: 'Pessoa inativa',
            profileImageId: person.profileImageId,
          ),
          const SizedBox(height: 8),
          _SummaryTile(
            icon: Icons.alternate_email,
            title: '@${user.username}',
            subtitle: 'Usuário Pontis',
            profileImageId: user.profileImageId,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.profileImageId,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? profileImageId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(
          displayName: title,
          radius: 20,
          profileImageId: profileImageId,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Icon(icon, color: AppColors.primary),
      ],
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

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
