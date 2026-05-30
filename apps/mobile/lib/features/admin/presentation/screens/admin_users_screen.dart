import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/admin/domain/entities/admin_user.dart';
import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:unishare_mobile/features/admin/presentation/widgets/admin_user_tile.dart';
import 'package:unishare_mobile/features/admin/presentation/widgets/role_picker_sheet.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

/// Admin → Users. Lists users and lets an admin change roles (real, via the
/// setUserRole callable) and toggle ban (TEMPLATE stub — see datasource TODO).
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            tooltip: 'Departments & courses',
            icon: const Icon(Icons.apartment_outlined),
            onPressed: () => context.go('/admin/departments'),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          key: const Key('admin-users-error'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $error', textAlign: TextAlign.center),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users'));
          }
          return ListView.builder(
            // Bottom inset clears the floating nav bar overlaying the shell.
            padding: const EdgeInsets.only(
              top: 8,
              bottom: MainNavBar.bottomInset + 8,
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return AdminUserTile(
                user: user,
                onChangeRole: () => _changeRole(context, ref, user),
                onToggleBan: () => _toggleBan(context, ref, user),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final selected = await showRolePicker(
      context,
      current: user.role,
      subtitle: user.name.isEmpty ? user.email : user.name,
    );
    if (selected == null || selected == user.role) return;

    final result = await ref
        .read(adminUserActionsProvider.notifier)
        .setRole(user.id, selected);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result is AsyncError
              ? 'Failed: ${result.error}'
              : 'Role updated to "$selected"',
        ),
      ),
    );
  }

  Future<void> _toggleBan(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final result = await ref
        .read(adminUserActionsProvider.notifier)
        .setBanned(user.id, !user.banned);
    if (!context.mounted) return;
    // TEMPLATE: setBanned has no backend yet, so this reports the
    // not-implemented error until it's built.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result is AsyncError ? 'Ban not available: ${result.error}' : 'Done',
        ),
      ),
    );
  }
}
