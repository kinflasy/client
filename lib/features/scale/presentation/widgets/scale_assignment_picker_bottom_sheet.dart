import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScaleAssignmentSelection {
  const ScaleAssignmentSelection({
    required this.role,
    required this.participant,
  });

  final LineupItemEntity role;
  final DepartmentParticipantEntity participant;
}

Future<ScaleAssignmentSelection?> showScaleAssignmentPickerBottomSheet({
  required BuildContext context,
  required String departmentId,
  required List<LineupItemEntity> roles,
  LineupItemEntity? initialRole,
}) {
  return showModalBottomSheet<ScaleAssignmentSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (context) => ScaleAssignmentPickerBottomSheet(
      departmentId: departmentId,
      roles: roles,
      initialRole: initialRole,
    ),
  );
}

class ScaleAssignmentPickerBottomSheet extends ConsumerStatefulWidget {
  const ScaleAssignmentPickerBottomSheet({
    super.key,
    required this.departmentId,
    required this.roles,
    this.initialRole,
  });

  final String departmentId;
  final List<LineupItemEntity> roles;
  final LineupItemEntity? initialRole;

  @override
  ConsumerState<ScaleAssignmentPickerBottomSheet> createState() =>
      _ScaleAssignmentPickerBottomSheetState();
}

class _ScaleAssignmentPickerBottomSheetState
    extends ConsumerState<ScaleAssignmentPickerBottomSheet> {
  final _searchController = TextEditingController();
  LineupItemEntity? _selectedRole;
  String _query = '';

  bool get _isChoosingRole => _selectedRole == null;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  if (!_isChoosingRole && widget.initialRole == null)
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => setState(() {
                        _selectedRole = null;
                        _query = '';
                        _searchController.clear();
                      }),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  Expanded(
                    child: Text(
                      _isChoosingRole ? 'Escolher função' : 'Escolher pessoa',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isChoosingRole
                  ? _RolePicker(
                      roles: widget.roles,
                      onSelect: (role) => setState(() => _selectedRole = role),
                    )
                  : _PersonPicker(
                      departmentId: widget.departmentId,
                      query: _query,
                      searchController: _searchController,
                      onQueryChanged: (value) => setState(() => _query = value),
                      onSelect: (participant) {
                        final role = _selectedRole;
                        if (role == null) return;
                        Navigator.of(context).pop(
                          ScaleAssignmentSelection(
                            role: role,
                            participant: participant,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.roles, required this.onSelect});

  final List<LineupItemEntity> roles;
  final ValueChanged<LineupItemEntity> onSelect;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return const _PickerStatus(
        icon: Icons.assignment_late_outlined,
        title: 'Nenhuma função definida',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: roles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final role = roles[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            onTap: () => onSelect(role),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            title: Text(_roleTitle(role)),
            subtitle: _roleSubtitle(role),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _PersonPicker extends ConsumerWidget {
  const _PersonPicker({
    required this.departmentId,
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
    required this.onSelect,
  });

  final String departmentId;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<DepartmentParticipantEntity> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(
      departmentParticipantsProvider(departmentId),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Pesquisar nome ou apelido...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: participantsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const _PickerStatus(
              icon: Icons.group_off_outlined,
              title: 'Não foi possível carregar os participantes.',
            ),
            data: (participants) {
              final filteredParticipants = _filterParticipants(
                participants,
                query,
              );

              if (filteredParticipants.isEmpty) {
                return const _PickerStatus(
                  icon: Icons.person_search_outlined,
                  title: 'Nenhum participante encontrado',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filteredParticipants.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final participant = filteredParticipants[index];
                  return _ParticipantTile(
                    participant: participant,
                    onTap: () => onSelect(participant),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, required this.onTap});

  final DepartmentParticipantEntity participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = _participantSubtitle(participant);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        leading: UserAvatar(
          displayName: participant.displayName,
          radius: 20,
          profileImageId: participant.profileImageId,
        ),
        title: Text(
          participant.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.add_circle_outline),
      ),
    );
  }
}

class _PickerStatus extends StatelessWidget {
  const _PickerStatus({required this.icon, required this.title});

  final IconData icon;
  final String title;

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
          ],
        ),
      ),
    );
  }
}

List<DepartmentParticipantEntity> _filterParticipants(
  List<DepartmentParticipantEntity> participants,
  String query,
) {
  final normalizedQuery = normalizeSearchTerm(query);
  final filtered = participants.where((participant) {
    if (normalizedQuery.isEmpty) return true;

    final displayName = normalizeSearchTerm(participant.displayName);
    final nickname = normalizeSearchTerm(participant.nickname ?? '');
    final username = normalizeSearchTerm(participant.username ?? '');
    return displayName.contains(normalizedQuery) ||
        nickname.contains(normalizedQuery) ||
        username.contains(normalizedQuery);
  }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

  return filtered;
}

String _roleTitle(LineupItemEntity item) {
  final roleName = item.role?.name.trim();
  if (roleName != null && roleName.isNotEmpty) return roleName;
  final description = item.description.trim();
  return description.isEmpty ? 'Função sem nome' : description;
}

Widget? _roleSubtitle(LineupItemEntity item) {
  final title = _roleTitle(item);
  final description = item.description.trim();
  if (description.isEmpty || description.toLowerCase() == title.toLowerCase()) {
    return null;
  }
  return Text(description, maxLines: 1, overflow: TextOverflow.ellipsis);
}

String? _participantSubtitle(DepartmentParticipantEntity participant) {
  final username = participant.username?.trim();
  if (username != null &&
      username.isNotEmpty &&
      username != participant.displayName) {
    return username;
  }

  final phone = participant.phone?.trim();
  if (phone != null && phone.isNotEmpty) return phone;
  return null;
}
