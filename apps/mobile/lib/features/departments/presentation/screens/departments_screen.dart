import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/departments_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ac = Theme.of(context).extension<AppColors>()!;

    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Departments'),
        leading: const BackButton(),
      ),
      body: departmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load departments.',
            style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
          ),
        ),
        data: (departments) {
          if (departments.isEmpty) {
            return Center(
              child: Text(
                'No departments found.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ac.textMuted,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: departments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final dept = departments[index];
              return GestureDetector(
                onTap: () => context.push(
                  '/more/departments/${dept.id}'
                  '?name=${Uri.encodeComponent(dept.name)}',
                ),
                child: _DepartmentTile(name: dept.name),
              );
            },
          );
        },
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  const _DepartmentTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ac.muted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.domain_outlined,
              size: 20,
              color: ac.mutedForeground,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
