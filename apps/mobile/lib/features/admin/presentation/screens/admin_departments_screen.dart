import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

/// Admin → Departments & courses. Lists departments and creates departments /
/// courses via real Firestore writes (admin-only per firestore.rules).
///
/// TEMPLATE: minimal create dialogs, no edit/delete/reorder, no university
/// picker (universityId is a free-text field). Friends can extend.
class AdminDepartmentsScreen extends ConsumerWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(adminDepartmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Departments & Courses')),
      // The admin screens live inside the shell, so the floating nav bar
      // overlays the body — lift the FAB above it.
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
          if (depts.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            // Clear the floating nav bar + the lifted FAB.
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MainNavBar.bottomInset + 88,
            ),
            itemCount: depts.length,
            itemBuilder: (context, index) {
              final dept = depts[index];
              return _DepartmentCard(
                id: dept.id,
                name: dept.name,
                onAddCourse: () => _createCourse(context, ref, dept.id),
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
          label: 'University ID (e.g. kmutt)',
          controller: uniCtl,
          keyboard: TextInputType.text,
        ),
      ],
    );

    if (ok == true) {
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

  Future<void> _createCourse(
    BuildContext context,
    WidgetRef ref,
    String departmentId,
  ) async {
    final codeCtl = TextEditingController();
    final nameCtl = TextEditingController();
    final yearCtl = TextEditingController();

    final ok = await _showFormDialog(
      context: context,
      title: 'New course in $departmentId',
      fields: [
        (
          label: 'Code (e.g. CSC101)',
          controller: codeCtl,
          keyboard: TextInputType.text,
        ),
        (label: 'Name', controller: nameCtl, keyboard: TextInputType.text),
        (
          label: 'Year level (optional)',
          controller: yearCtl,
          keyboard: TextInputType.number,
        ),
      ],
    );

    if (ok == true) {
      final result = await ref
          .read(adminCatalogActionsProvider.notifier)
          .createCourse(
            departmentId: departmentId,
            code: codeCtl.text.trim(),
            name: nameCtl.text.trim(),
            yearLevel: int.tryParse(yearCtl.text.trim()),
          );
      if (context.mounted) _report(context, result, 'Course created');
    }
    codeCtl.dispose();
    nameCtl.dispose();
    yearCtl.dispose();
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
        content: Column(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.id,
    required this.name,
    required this.onAddCourse,
  });

  final String id;
  final String name;
  final VoidCallback onAddCourse;

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
              child: Icon(Icons.apartment_outlined, size: 20, color: ac.amber),
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
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Course'),
              style: TextButton.styleFrom(foregroundColor: cs.onSurface),
              onPressed: onAddCourse,
            ),
          ],
        ),
      ),
    );
  }
}

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
