import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/presentation/widgets/role_selection_bottom_sheet.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
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
  final Set<String> _removedItemIds = {};
  bool _initialized = false;
  String _initialName = '';
  List<_InitialSlotSnapshot> _initialSlots = const [];

  bool get _isEditing => widget.lineupId != null;

  @override
  void initState() {
    super.initState();
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

    if (_isEditing) {
      final lineupAsync = ref.watch(lineupWithItemsProvider(widget.lineupId!));
      return lineupAsync.when(
        loading: () => _buildScaffold(
          context,
          isSaving: isSaving,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => _buildScaffold(
          context,
          isSaving: isSaving,
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
            body: _buildForm(isSaving: isSaving),
          );
        },
      );
    }

    _initializeForCreate();
    return _buildScaffold(
      context,
      isSaving: isSaving,
      body: _buildForm(isSaving: isSaving),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required bool isSaving,
    required Widget body,
  }) {
    return PopScope(
      canPop: !_hasUnsavedChanges() || isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || isSaving) return;
        await _confirmDiscardAndPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar lineup' : 'Novo lineup'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            onPressed: isSaving ? null : _handleBackPressed,
          ),
          actions: [
            if (_isEditing)
              IconButton(
                tooltip: 'Remover escala',
                onPressed: isSaving ? null : _confirmAndDeleteLineup,
                icon: const Icon(Icons.delete_outline),
              ),
            TextButton(
              onPressed: _canSave(isSaving) ? _save : null,
              child: const Text('Salvar'),
            ),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _buildForm({required bool isSaving}) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          TextFormField(
            controller: _nameController,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome do lineup',
              hintText: 'Ex: Louvor - Culto dominical',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome do lineup.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isSaving ? null : _showRolePicker,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar papel'),
          ),
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
                onRemove: isSaving ? null : () => _removeSlotAt(index),
              ),
              if (index < _slots.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  void _initializeForCreate() {
    if (_initialized) return;
    _initialized = true;
    _initialName = '';
    _initialSlots = const [];
  }

  void _initializeFromLineup(LineupEntity lineup) {
    if (_initialized) return;

    _initialized = true;
    _initialName = lineup.name;
    _nameController.text = lineup.name;
    _slots
      ..clear()
      ..addAll((lineup.items ?? const []).map(_LineupRoleSlot.fromItem));
    _initialSlots = _slots.map(_InitialSlotSnapshot.fromSlot).toList();
  }

  bool _canSave(bool isSaving) {
    return !isSaving && _nameController.text.trim().isNotEmpty;
  }

  bool _hasUnsavedChanges() {
    if (!_initialized) return false;
    if (_nameController.text.trim() != _initialName.trim()) return true;
    if (_removedItemIds.isNotEmpty) return true;
    if (_slots.length != _initialSlots.length) return true;

    for (var index = 0; index < _slots.length; index++) {
      if (_InitialSlotSnapshot.fromSlot(_slots[index]) !=
          _initialSlots[index]) {
        return true;
      }
    }

    return false;
  }

  Future<void> _handleBackPressed() async {
    if (!_hasUnsavedChanges()) {
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

  Future<void> _confirmAndDeleteLineup() async {
    final shouldDelete = await showActionConfirmationDialog(
      context,
      title: 'Remover escala?',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!mounted || !shouldDelete) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(lineupActionsProvider.notifier)
        .delete(departmentId: widget.departmentId, lineupId: widget.lineupId!);

    if (!mounted) return;

    result.fold(
      (failure) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível remover a escala.')),
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
        setState(() {
          _slots.add(_LineupRoleSlot.fromRole(role));
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

  void _removeSlotAt(int index) {
    final slot = _slots.removeAt(index);
    if (slot.itemId != null) _removedItemIds.add(slot.itemId!);
    setState(() {});
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final lineupActions = ref.read(lineupActionsProvider.notifier);
    final itemActions = ref.read(lineupItemActionsProvider.notifier);
    final name = _nameController.text.trim();

    if (_isEditing) {
      final lineupResult = await lineupActions.update(
        departmentId: widget.departmentId,
        lineupId: widget.lineupId!,
        request: LineupRequestModel(name: name),
      );
      if (lineupResult.isLeft()) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o lineup.')),
        );
        return;
      }

      for (final itemId in _removedItemIds) {
        final result = await itemActions.delete(
          lineupId: widget.lineupId!,
          itemId: itemId,
          departmentId: widget.departmentId,
        );
        if (result.isLeft()) {
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Não foi possível salvar o lineup.')),
          );
          return;
        }
      }

      for (final slot in _slots.where((slot) => slot.itemId == null)) {
        final result = await itemActions.create(
          lineupId: widget.lineupId!,
          departmentId: widget.departmentId,
          request: LineupItemRequestModel(
            roleId: slot.role.id,
            description: slot.description,
          ),
        );
        if (result.isLeft()) {
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Não foi possível salvar o lineup.')),
          );
          return;
        }
      }

      if (!mounted) return;
      context.pop();
      return;
    }

    final lineupResult = await lineupActions.create(
      departmentId: widget.departmentId,
      request: LineupRequestModel(name: name),
    );

    LineupEntity? createdLineup;
    lineupResult.fold(
      (_) => createdLineup = null,
      (lineup) => createdLineup = lineup,
    );
    if (createdLineup == null) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o lineup.')),
      );
      return;
    }

    for (final slot in _slots) {
      final result = await itemActions.create(
        lineupId: createdLineup!.id,
        departmentId: widget.departmentId,
        request: LineupItemRequestModel(
          roleId: slot.role.id,
          description: slot.description,
        ),
      );
      if (result.isLeft()) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o lineup.')),
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

class _InitialSlotSnapshot {
  const _InitialSlotSnapshot({
    required this.itemId,
    required this.roleId,
    required this.description,
  });

  factory _InitialSlotSnapshot.fromSlot(_LineupRoleSlot slot) {
    return _InitialSlotSnapshot(
      itemId: slot.itemId,
      roleId: slot.role.id,
      description: slot.description,
    );
  }

  final String? itemId;
  final String roleId;
  final String description;

  @override
  bool operator ==(Object other) {
    return other is _InitialSlotSnapshot &&
        other.itemId == itemId &&
        other.roleId == roleId &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(itemId, roleId, description);
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
  const _RoleSlotTile({required this.slot, required this.onRemove});

  final _LineupRoleSlot slot;
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
