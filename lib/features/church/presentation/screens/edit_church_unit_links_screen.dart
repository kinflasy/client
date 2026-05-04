import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/church/domain/entities/church_link_entity.dart';
import 'package:client/features/church/providers/church_general_info_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditChurchUnitLinksScreen extends ConsumerStatefulWidget {
  const EditChurchUnitLinksScreen({super.key});

  @override
  ConsumerState<EditChurchUnitLinksScreen> createState() =>
      _EditChurchUnitLinksScreenState();
}

class _EditChurchUnitLinksScreenState
    extends ConsumerState<EditChurchUnitLinksScreen> {
  String? _editingId;
  final _labelController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _startEdit(ChurchLinkEntity link) {
    setState(() {
      _editingId = link.id;
      _labelController.text = link.label;
      _urlController.text = link.url;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _labelController.clear();
      _urlController.clear();
    });
  }

  Future<void> _saveEdit(String linkId) async {
    final label = _labelController.text.trim();
    final url = _urlController.text.trim();
    if (label.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rótulo e URL são obrigatórios.')),
      );
      return;
    }

    final result = await ref
        .read(churchGeneralInfoActionsProvider)
        .updateUnitLink(linkId: linkId, label: label, url: url);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.toString()))),
      (_) {
        ref.invalidate(activeUnitLinksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link atualizado com sucesso.')),
        );
        _cancelEdit();
      },
    );
  }

  Future<void> _createLink() async {
    final label = _labelController.text.trim();
    final url = _urlController.text.trim();
    if (label.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rótulo e URL são obrigatórios.')),
      );
      return;
    }

    final result = await ref
        .read(churchGeneralInfoActionsProvider)
        .createActiveUnitLink(label: label, url: url);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.toString()))),
      (_) {
        ref.invalidate(activeUnitLinksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link criado com sucesso.')),
        );
        _labelController.clear();
        _urlController.clear();
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _confirmAndDelete(String linkId) async {
    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Remover link',
      message: 'Tem certeza que deseja remover este link?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );

    if (!confirmed) return;

    final result = await ref
        .read(churchGeneralInfoActionsProvider)
        .deleteUnitLink(linkId: linkId);
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.toString()))),
      (_) {
        ref.invalidate(activeUnitLinksProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Link removido.')));
      },
    );
  }

  void _openAddBottomSheet() {
    _labelController.clear();
    _urlController.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Rótulo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createLink,
              child: const Text('Adicionar link'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(activeUnitLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Links externos'),
        backgroundColor: AppColors.surface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddBottomSheet,
        child: const Icon(Icons.add),
      ),
      body: linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erro ao carregar links.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(activeUnitLinksProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (links) {
          if (links.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nenhum link cadastrado.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _openAddBottomSheet,
                    child: const Text('Adicionar primeiro link'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: links.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final link = links[index];
              final isEditing = _editingId == link.id;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: isEditing
                      ? Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _labelController,
                                    decoration: const InputDecoration(
                                      labelText: 'Rótulo',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _urlController,
                                    decoration: const InputDecoration(
                                      labelText: 'URL',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () => _saveEdit(link.id),
                                  tooltip: 'Salvar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _cancelEdit,
                                  tooltip: 'Cancelar',
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    link.label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    link.url,
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _startEdit(link),
                                  tooltip: 'Editar link',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmAndDelete(link.id),
                                  tooltip: 'Remover link',
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
