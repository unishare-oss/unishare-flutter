import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:unishare_mobile/features/admin/presentation/widgets/admin_user_tile.dart';

/// Admin → Users. Lists users and lets an admin change roles (real, via the
/// setUserRole callable) and toggle ban (TEMPLATE stub — see datasource TODO).
///
/// Reachable only by admins (route guard in core/router). The underlying
/// `users` read is also gated by `isAdmin()` in firestore.rules, so a
/// non-admin who somehow lands here just sees the error state.
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
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return AdminUserTile(
                user: user,
                onRoleSelected: (role) =>
                    _setRole(context, ref, user.id, user.name, role),
                onToggleBan: () =>
                    _toggleBan(context, ref, user.id, !user.banned),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _setRole(
    BuildContext context,
    WidgetRef ref,
    String uid,
    String name,
    String role,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change role'),
        content: Text('Set ${name.isEmpty ? uid : name} to "$role"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(adminUserActionsProvider.notifier).setRole(uid, role);
    if (!context.mounted) return;
    final state = ref.read(adminUserActionsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state is AsyncError
              ? 'Failed: ${state.error}'
              : 'Role updated to "$role"',
        ),
      ),
    );
  }

  Future<void> _toggleBan(
    BuildContext context,
    WidgetRef ref,
    String uid,
    bool banned,
  ) async {
    await ref.read(adminUserActionsProvider.notifier).setBanned(uid, banned);
    if (!context.mounted) return;
    final state = ref.read(adminUserActionsProvider);
    // TEMPLATE: setBanned throws UnimplementedError today, so this always
    // reports the not-implemented error until the backend is built.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state is AsyncError ? 'Ban not available: ${state.error}' : 'Done',
        ),
      ),
    );
  }
}
