import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

/// Admin departments — lists departments with clickable drill-down to courses
/// and a PopupMenuButton with edit/delete per tile.
///
/// Template TODOs:
///   - universityId is free-text on create — no university picker yet.
///   - No use-case layer; collapsed for compactness.
class AdminDepartmentsScreen extends ConsumerWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(adminDepartmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: MainNavBar.bottomInset),
        child: FloatingActionButton.extended(
          onPressed: () => _createDepartment(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Department'),
        ),
      ),
      body: deptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          key: const Key('admin-departments-error'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $error', textAlign: TextAlign.center),
          ),
        ),
        data: (depts) {
          if (depts.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MainNavBar.bottomInset + 88,
            ),
            itemCount: depts.length,
            itemBuilder: (context, index) {
              final dept = depts[index];
              return _DepartmentTile(
                id: dept.id,
                name: dept.name,
                onTap: () => context.push(
                  '/admin/departments/${dept.id}/courses'
                  '?name=${Uri.encodeComponent(dept.name)}',
                ),
                onEdit: () => _editDepartment(context, ref, dept.id, dept.name),
                onDelete: () =>
                    _deleteDepartment(context, ref, dept.id, dept.name),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createDepartment(BuildContext context, WidgetRef ref) async {
    final idCtl = TextEditingController();
    final nameCtl = TextEditingController();
    // TODO: replace free-text universityId with a dropdown university picker.
    final uniCtl = TextEditingController();

    final ok = await _showFormDialog(
      context: context,
      title: 'New department',
      fields: [
        (
          label: 'ID (e.g. cs)',
          controller: idCtl,
          keyboard: TextInputType.text,
        ),
        (label: 'Name', controller: nameCtl, keyboard: TextInputType.text),
        (
          label: 'University ID (free-text)',
          controller: uniCtl,
          keyboard: TextInputType.text,
        ),
      ],
    );

    if (ok == true && context.mounted) {
      final result = await ref
          .read(adminCatalogActionsProvider.notifier)
          .createDepartment(
            id: idCtl.text.trim(),
            name: nameCtl.text.trim(),
            universityId: uniCtl.text.trim(),
          );
      if (context.mounted) _report(context, result, 'Department created');
    }
    idCtl.dispose();
    nameCtl.dispose();
    uniCtl.dispose();
  }

  Future<void> _editDepartment(
    BuildContext context,
    WidgetRef ref,
    String id,
    String currentName,
  ) async {
    final nameCtl = TextEditingController(text: currentName);
    final ok = await _showFormDialog(
      context: context,
      title: 'Edit department',
      fields: [
        (label: 'Name', controller: nameCtl, keyboard: TextInputType.text),
      ],
    );
    if (ok == true && context.mounted) {
      final result = await ref
          .read(adminCatalogActionsProvider.notifier)
          .updateDepartment(id, nameCtl.text.trim());
      if (context.mounted) _report(context, result, 'Department updated');
    }
    nameCtl.dispose();
  }

  Future<void> _deleteDepartment(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete department?'),
        content: Text(
          'Delete "$name"? This cannot be undone. '
          'Courses inside are NOT removed automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(adminCatalogActionsProvider.notifier)
        .deleteDepartment(id);
    if (context.mounted) _report(context, result, 'Department deleted');
  }

  void _report(BuildContext context, AsyncValue<void> result, String okMsg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result is AsyncError ? 'Failed: ${result.error}' : okMsg),
      ),
    );
  }

  Future<bool?> _showFormDialog({
    required BuildContext context,
    required String title,
    required List<
      ({String label, TextEditingController controller, TextInputType keyboard})
    >
    fields,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: f.controller,
                    keyboardType: f.keyboard,
                    decoration: InputDecoration(
                      labelText: f.label,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  const _DepartmentTile({
    required this.id,
    required this.name,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final String id;
  final String name;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ac = theme.extension<AppColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ac.amberSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.apartment_outlined,
                  size: 20,
                  color: ac.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      id,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ac.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: ac.textMuted),
              PopupMenuButton<_DeptAction>(
                tooltip: 'More',
                icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                onSelected: (action) {
                  switch (action) {
                    case _DeptAction.edit:
                      onEdit();
                    case _DeptAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _DeptAction.edit,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: cs.onSurface,
                        ),
                        const SizedBox(width: 10),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _DeptAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: cs.error),
                        const SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: cs.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DeptAction { edit, delete }

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.apartment_outlined, size: 40, color: ac.textMuted),
          const SizedBox(height: 12),
          Text(
            'No departments yet',
            style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
          ),
        ],
      ),
    );
  }
}
