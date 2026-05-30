import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

/// Admin courses screen — shows courses for a department grouped by year tabs.
/// Each course tile has a PopupMenuButton with edit/delete.
///
/// Template TODOs:
///   - No use-case layer; collapsed for compactness.
class AdminCoursesScreen extends ConsumerWidget {
  const AdminCoursesScreen({
    super.key,
    required this.deptId,
    required this.departmentName,
  });

  final String deptId;
  final String departmentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(departmentName),
          leading: const BackButton(),
          bottom: TabBar(
            indicatorColor: ac.amber,
            labelColor: ac.amber,
            unselectedLabelColor: ac.textMuted,
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Year 1'),
              Tab(text: 'Year 2'),
              Tab(text: 'Year 3'),
              Tab(text: 'Year 4'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final year in [1, 2, 3, 4])
              _CoursesTab(deptId: deptId, year: year),
          ],
        ),
      ),
    );
  }
}

class _CoursesTab extends ConsumerWidget {
  const _CoursesTab({required this.deptId, required this.year});

  final String deptId;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final coursesAsync = ref.watch(adminCoursesProvider((deptId, year)));

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: MainNavBar.bottomInset),
        child: FloatingActionButton.extended(
          heroTag: 'add-course-year-$year',
          onPressed: () => _createCourse(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Course'),
        ),
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load courses.',
            style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
          ),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Text(
                'No courses for Year $year.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ac.textMuted,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MainNavBar.bottomInset + 88,
            ),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _CourseTile(
                id: course.id,
                name: course.name,
                onEdit: () =>
                    _editCourse(context, ref, course.id, course.name),
                onDelete: () =>
                    _deleteCourse(context, ref, course.id, course.name),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createCourse(BuildContext context, WidgetRef ref) async {
    final codeCtl = TextEditingController();
    final nameCtl = TextEditingController();
    final yearCtl = TextEditingController(text: year.toString());

    final ok = await _showFormDialog(
      context: context,
      title: 'New course — Year $year',
      fields: [
        (
          label: 'Code (e.g. CSC101)',
          controller: codeCtl,
          keyboard: TextInputType.text,
        ),
        (label: 'Name', controller: nameCtl, keyboard: TextInputType.text),
        (
          label: 'Year level',
          controller: yearCtl,
          keyboard: TextInputType.number,
        ),
      ],
    );

    if (ok == true && context.mounted) {
      final result = await ref
          .read(adminCatalogActionsProvider.notifier)
          .createCourse(
            departmentId: deptId,
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

  Future<void> _editCourse(
    BuildContext context,
    WidgetRef ref,
    String courseId,
    String currentName,
  ) async {
    final nameCtl = TextEditingController(text: currentName);
    final yearCtl = TextEditingController(text: year.toString());

    final ok = await _showFormDialog(
      context: context,
      title: 'Edit course',
      fields: [
        (label: 'Name', controller: nameCtl, keyboard: TextInputType.text),
        (
          label: 'Year level',
          controller: yearCtl,
          keyboard: TextInputType.number,
        ),
      ],
    );

    if (ok == true && context.mounted) {
      final result = await ref
          .read(adminCatalogActionsProvider.notifier)
          .updateCourse(
            deptId,
            courseId,
            nameCtl.text.trim(),
            int.tryParse(yearCtl.text.trim()),
          );
      if (context.mounted) _report(context, result, 'Course updated');
    }
    nameCtl.dispose();
    yearCtl.dispose();
  }

  Future<void> _deleteCourse(
    BuildContext context,
    WidgetRef ref,
    String courseId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text('Delete "$name"? This cannot be undone.'),
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
        .deleteCourse(deptId, courseId);
    if (context.mounted) _report(context, result, 'Course deleted');
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
    > fields,
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

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.id,
    required this.name,
    required this.onEdit,
    required this.onDelete,
  });

  final String id;
  final String name;
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ac.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.book_outlined,
                size: 20,
                color: ac.mutedForeground,
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
            PopupMenuButton<_CourseAction>(
              tooltip: 'More',
              icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
              onSelected: (action) {
                switch (action) {
                  case _CourseAction.edit:
                    onEdit();
                  case _CourseAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _CourseAction.edit,
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
                  value: _CourseAction.delete,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: cs.error,
                      ),
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
    );
  }
}

enum _CourseAction { edit, delete }
