import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/admin/domain/entities/admin_user.dart';

/// One row in the admin users list: identity + a role menu + a ban toggle.
///
/// TEMPLATE: presentation only — all mutations are delegated to the callbacks
/// so the parent screen owns the provider wiring and feedback.
class AdminUserTile extends StatelessWidget {
  const AdminUserTile({
    super.key,
    required this.user,
    required this.onRoleSelected,
    required this.onToggleBan,
  });

  final AdminUser user;
  final ValueChanged<String> onRoleSelected;
  final VoidCallback onToggleBan;

  static const _roles = ['student', 'moderator', 'admin'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        foregroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
            ? CachedNetworkImageProvider(user.photoUrl!)
            : null,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        user.name.isEmpty ? '(no name)' : user.name,
        style: theme.textTheme.titleSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        user.email,
        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleChip(role: user.role),
          PopupMenuButton<String>(
            tooltip: 'Change role',
            icon: const Icon(Icons.expand_more),
            onSelected: onRoleSelected,
            itemBuilder: (context) => [
              for (final r in _roles)
                CheckedPopupMenuItem(
                  value: r,
                  checked: r == user.role,
                  child: Text(r),
                ),
            ],
          ),
          IconButton(
            tooltip: user.banned ? 'Unban' : 'Ban',
            onPressed: onToggleBan,
            icon: Icon(
              user.banned ? Icons.block : Icons.block_outlined,
              color: user.banned ? cs.error : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (bg, fg) = switch (role) {
      'admin' => (cs.errorContainer, cs.onErrorContainer),
      'moderator' => (cs.tertiaryContainer, cs.onTertiaryContainer),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(role, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}
