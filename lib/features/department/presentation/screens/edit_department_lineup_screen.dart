import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/presentation/widgets/role_selection_bottom_sheet.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditDepartmentLineupScreen extends ConsumerStatefulWidget {
  const EditDepartmentLineupScreen({
    super.key,
    required this.departmentId,
    this.lineupId,
  });

  final String departmentId;
  final String? lineupId;

  @override
  ConsumerState<EditDepartmentLineupScreen> createState() =>
      _EditDepartmentLineupScreenState();
}

class _EditDepartmentLineupScreenState
    extends ConsumerState<EditDepartmentLineupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<_LineupRoleSlot> _slots = [];
  bool _initialized = false;
  bool _isNameEditing = true;
  String? _persistedLineupId;
  String _persistedName = '';

  bool get _isCreateRoute => widget.lineupId == null;
  bool get _hasPersistedLineup => _persistedLineupId != null;
  bool get _isCreatingLineup => _isCreateRoute && !_hasPersistedLineup;

  @override
  void initState() {
    super.initState();
    _persistedLineupId = widget.lineupId;
    _isNameEditing = _isCreateRoute;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        ref.watch(lineupActionsProvider).isLoading ||
        ref.watch(lineupItemActionsProvider).isLoading;
    final canManageDepartment =
        ref
            .watch(sessionPermissionsProvider)
            .whenOrNull(
              data: (permissions) =>
                  permissions.canManageDept(widget.departmentId),
            ) ??
        false;
    final canManage = _isCreateRoute || canManageDepartment;

    if (widget.lineupId != null) {
      final lineupAsync = ref.watch(lineupWithItemsProvider(widget.lineupId!));
      return lineupAsync.when(
        loading: () => _buildScaffold(
          context,
          isSaving: isSaving,
          canManage: canManage,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => _buildScaffold(
          context,
          isSaving: isSaving,
          canManage: canManage,
          body: const _InlineStatus(
            icon: Icons.assignment_late_outlined,
            title: 'Não foi possível carregar o lineup.',
            subtitle: 'Tente novamente em instantes.',
          ),
        ),
        data: (lineup) {
          _initializeFromLineup(lineup);
          return _buildScaffold(
            context,
            isSaving: isSaving,
            canManage: canManage,
            body: _buildForm(isSaving: isSaving, canManage: canManage),
          );
        },
      );
    }

    _initializeForCreate();
    return _buildScaffold(
      context,
      isSaving: isSaving,
      canManage: canManage,
      body: _buildForm(isSaving: isSaving, canManage: canManage),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required bool isSaving,
    required bool canManage,
    required Widget body,
  }) {
    return PopScope(
      canPop: !_hasUnsavedNameChanges() || isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || isSaving) return;
        await _confirmDiscardAndPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_appBarTitle),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            onPressed: isSaving ? null : _handleBackPressed,
          ),
          actions: [
            if (!_isCreateRoute && canManage)
              PopupMenuButton<_LineupMenuAction>(
                tooltip: 'Mais opções',
                onSelected: (action) {
                  switch (action) {
                    case _LineupMenuAction.delete:
                      _confirmAndDeleteLineup();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _LineupMenuAction.delete,
                    child: Text('Deletar escala'),
                  ),
                ],
              ),
          ],
        ),
        body: body,
      ),
    );
  }

  String get _appBarTitle {
    if (_isCreateRoute) return 'Novo lineup';
    if (_persistedName.isNotEmpty) return _persistedName;
    return 'Lineup';
  }

  Widget _buildForm({required bool isSaving, required bool canManage}) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _buildNameSection(isSaving: isSaving, canManage: canManage),
          if (_hasPersistedLineup) ...[
            const SizedBox(height: 24),
            _buildRolesSection(isSaving: isSaving, canManage: canManage),
          ],
        ],
      ),
    );
  }

  Widget _buildNameSection({required bool isSaving, required bool canManage}) {
    final buttonLabel = _isCreatingLineup
        ? 'Criar'
        : (_isNameEditing ? 'Salvar' : 'Editar nome');
    final canPressNameButton =
        canManage &&
        !isSaving &&
        (!_isNameEditing || _nameController.text.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          enabled: canManage && _isNameEditing && !isSaving,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nome do lineup',
            hintText: 'Ex: Louvor - Culto dominical',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (!_isNameEditing && !_isCreatingLineup) return null;
            if (value == null || value.trim().isEmpty) {
              return 'Informe o nome do lineup.';
            }
            return null;
          },
        ),
        if (canManage) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: canPressNameButton ? _handleNameButtonPressed : null,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRolesSection({required bool isSaving, required bool canManage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Papéis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _RoleCountBadge(count: _slots.length),
          ],
        ),
        if (canManage) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isSaving ? null : _showRolePicker,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar papel'),
          ),
        ],
        const SizedBox(height: 16),
        if (_slots.isEmpty)
          const _EmptyRolesState()
        else ...[
          const Text(
            'O mesmo papel pode aparecer mais de uma vez',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _slots.length; index++) ...[
            _RoleSlotTile(
              slot: _slots[index],
              canRemove: canManage,
              onRemove: isSaving ? null : () => _removeSlotAt(index),
            ),
            if (index < _slots.length - 1) const SizedBox(height: 8),
          ],
        ],
        if (_isCreateRoute && canManage) ...[
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSaving ? null : _saveCreatedLineupRoles,
            child: const Text('Salvar papéis'),
          ),
        ],
      ],
    );
  }

  void _initializeForCreate() {
    if (_initialized) return;
    _initialized = true;
    _persistedName = '';
  }

  void _initializeFromLineup(LineupEntity lineup) {
    if (_initialized) return;

    _initialized = true;
    _persistedLineupId = lineup.id;
    _persistedName = lineup.name;
    _isNameEditing = false;
    _nameController.text = lineup.name;
    _slots
      ..clear()
      ..addAll((lineup.items ?? const []).map(_LineupRoleSlot.fromItem));
  }

  bool _hasUnsavedNameChanges() {
    if (!_initialized || !_isNameEditing) return false;
    return _nameController.text.trim() != _persistedName.trim();
  }

  Future<void> _handleBackPressed() async {
    if (!_hasUnsavedNameChanges()) {
      context.pop();
      return;
    }
    await _confirmDiscardAndPop();
  }

  Future<void> _confirmDiscardAndPop() async {
    final shouldDiscard = await showActionConfirmationDialog(
      context,
      title: 'Descartar alterações?',
      message: 'Existem alterações não salvas. Deseja sair mesmo assim?',
      confirmLabel: 'Sair',
      isDestructive: true,
    );
    if (!mounted || !shouldDiscard) return;
    context.pop();
  }

  Future<void> _handleNameButtonPressed() async {
    if (_isCreatingLineup) {
      await _createLineupName();
      return;
    }

    if (!_isNameEditing) {
      setState(() => _isNameEditing = true);
      return;
    }

    await _saveLineupName();
  }

  Future<void> _createLineupName() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final result = await ref
        .read(lineupActionsProvider.notifier)
        .create(
          departmentId: widget.departmentId,
          request: LineupRequestModel(name: name),
        );

    result.fold(
      (failure) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível criar o lineup.')),
        );
      },
      (lineup) {
        if (lineup.id.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Não foi possível identificar o lineup criado.'),
            ),
          );
          return;
        }

        setState(() {
          _persistedLineupId = lineup.id;
          _persistedName = lineup.name;
          _nameController.text = lineup.name;
          _isNameEditing = false;
        });
      },
    );
  }

  Future<void> _saveLineupName() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final result = await ref
        .read(lineupActionsProvider.notifier)
        .update(
          departmentId: widget.departmentId,
          lineupId: _persistedLineupId!,
          request: LineupRequestModel(name: name),
        );

    result.fold(
      (failure) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o nome.')),
        );
      },
      (lineup) {
        setState(() {
          _persistedName = lineup.name;
          _nameController.text = lineup.name;
          _isNameEditing = false;
        });
      },
    );
  }

  Future<void> _confirmAndDeleteLineup() async {
    final shouldDelete = await showActionConfirmationDialog(
      context,
      title: 'Deletar escala?',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Deletar',
      isDestructive: true,
    );
    if (!mounted || !shouldDelete) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(lineupActionsProvider.notifier)
        .delete(
          departmentId: widget.departmentId,
          lineupId: _persistedLineupId!,
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível deletar a escala.')),
        );
      },
      (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Escala removida.')),
        );
        context.pop();
      },
    );
  }

  Future<void> _showRolePicker() async {
    await showRoleSelectionBottomSheet(
      context: context,
      selectedRoleCounts: _roleCounts(),
      onSelect: (role) {
        if (_isCreateRoute) {
          setState(() {
            _slots.add(_LineupRoleSlot.fromRole(role));
          });
          return;
        }

        _addPersistedRole(role);
      },
    );
  }

  Future<void> _addPersistedRole(RoleEntity role) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(lineupItemActionsProvider.notifier)
        .create(
          lineupId: _persistedLineupId!,
          departmentId: widget.departmentId,
          request: LineupItemRequestModel(
            roleId: role.id,
            description: role.name,
          ),
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível adicionar o papel.')),
        );
      },
      (item) {
        setState(() {
          _slots.add(_LineupRoleSlot.fromItem(item));
        });
      },
    );
  }

  Map<String, int> _roleCounts() {
    final counts = <String, int>{};
    for (final slot in _slots) {
      counts[slot.role.id] = (counts[slot.role.id] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _removeSlotAt(int index) async {
    final slot = _slots[index];
    if (_isCreateRoute) {
      setState(() => _slots.removeAt(index));
      return;
    }

    final shouldRemove = await showActionConfirmationDialog(
      context,
      title: 'Remover papel?',
      message: 'Deseja remover este papel do lineup?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!mounted || !shouldRemove) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(lineupItemActionsProvider.notifier)
        .delete(
          lineupId: _persistedLineupId!,
          itemId: slot.itemId!,
          departmentId: widget.departmentId,
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível remover o papel.')),
        );
      },
      (_) {
        setState(() => _slots.removeAt(index));
      },
    );
  }

  Future<void> _saveCreatedLineupRoles() async {
    final messenger = ScaffoldMessenger.of(context);
    final lineupId = _persistedLineupId;
    if (lineupId == null || lineupId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar o lineup criado.'),
        ),
      );
      return;
    }

    for (final slot in _slots) {
      final result = await ref
          .read(lineupItemActionsProvider.notifier)
          .create(
            lineupId: lineupId,
            departmentId: widget.departmentId,
            request: LineupItemRequestModel(
              roleId: slot.role.id,
              description: slot.description,
            ),
          );
      if (result.isLeft()) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar os papéis.')),
        );
        return;
      }
    }

    if (!mounted) return;
    context.pop();
  }
}

class _LineupRoleSlot {
  const _LineupRoleSlot({
    required this.role,
    required this.description,
    this.itemId,
  });

  factory _LineupRoleSlot.fromRole(RoleEntity role) {
    return _LineupRoleSlot(role: role, description: role.name);
  }

  factory _LineupRoleSlot.fromItem(LineupItemEntity item) {
    final role =
        item.role ??
        RoleEntity(
          id: item.roleId,
          name: item.description.isEmpty ? 'Papel' : item.description,
          slug: item.roleId,
        );
    return _LineupRoleSlot(
      itemId: item.id,
      role: role,
      description: item.description.isEmpty ? role.name : item.description,
    );
  }

  final String? itemId;
  final RoleEntity role;
  final String description;
}

class _RoleCountBadge extends StatelessWidget {
  const _RoleCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleSlotTile extends StatelessWidget {
  const _RoleSlotTile({
    required this.slot,
    required this.canRemove,
    required this.onRemove,
  });

  final _LineupRoleSlot slot;
  final bool canRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E3E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              slot.role.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (canRemove)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Remover papel',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

class _EmptyRolesState extends StatelessWidget {
  const _EmptyRolesState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Nenhum papel adicionado ainda',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
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

enum _LineupMenuAction { delete }
