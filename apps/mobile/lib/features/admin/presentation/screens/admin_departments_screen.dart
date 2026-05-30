import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDepartment(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Department'),
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
            return const Center(child: Text('No departments yet'));
          }
          return ListView.builder(
            itemCount: depts.length,
            itemBuilder: (context, index) {
              final dept = depts[index];
              return ListTile(
                title: Text(dept.name),
                subtitle: Text(dept.id),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Course'),
                  onPressed: () => _createCourse(context, ref, dept.id),
                ),
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
      await ref
          .read(adminCatalogActionsProvider.notifier)
          .createDepartment(
            id: idCtl.text.trim(),
            name: nameCtl.text.trim(),
            universityId: uniCtl.text.trim(),
          );
      if (context.mounted) _report(context, ref, 'Department created');
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
      await ref
          .read(adminCatalogActionsProvider.notifier)
          .createCourse(
            departmentId: departmentId,
            code: codeCtl.text.trim(),
            name: nameCtl.text.trim(),
            yearLevel: int.tryParse(yearCtl.text.trim()),
          );
      if (context.mounted) _report(context, ref, 'Course created');
    }
    codeCtl.dispose();
    nameCtl.dispose();
    yearCtl.dispose();
  }

  void _report(BuildContext context, WidgetRef ref, String successMsg) {
    if (!context.mounted) return;
    final state = ref.read(adminCatalogActionsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state is AsyncError ? 'Failed: ${state.error}' : successMsg,
        ),
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
