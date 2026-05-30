import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

typedef _RoleSpec = ({String value, String label, String desc, IconData icon});

const List<_RoleSpec> _roles = [
  (
    value: 'student',
    label: 'Student',
    desc: 'Browse and post content',
    icon: Icons.school_outlined,
  ),
  (
    value: 'moderator',
    label: 'Moderator',
    desc: 'Review and approve or reject posts',
    icon: Icons.shield_outlined,
  ),
  (
    value: 'admin',
    label: 'Admin',
    desc: 'Full project control',
    icon: Icons.admin_panel_settings_outlined,
  ),
];

/// Modern role selector — a modal bottom sheet listing each role with an icon
/// and a one-line description, highlighting the current one. Returns the
/// chosen role value, or null if dismissed.
Future<String?> showRolePicker(
  BuildContext context, {
  required String current,
  String? subtitle,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) =>
        _RolePickerSheet(current: current, subtitle: subtitle),
  );
}

class _RolePickerSheet extends StatelessWidget {
  const _RolePickerSheet({required this.current, this.subtitle});

  final String current;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Change role', style: theme.textTheme.titleMedium),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.extension<AppColors>()!.textMuted,
                ),
              ),
            ),
          const SizedBox(height: 4),
          for (final role in _roles)
            _RoleOption(
              role: role,
              selected: role.value == current,
              onTap: () => Navigator.of(context).pop(role.value),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final _RoleSpec role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ac = theme.extension<AppColors>()!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? ac.amberSubtle : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                role.icon,
                size: 20,
                color: selected ? ac.amber : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    role.desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ac.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: ac.amber, size: 22),
          ],
        ),
      ),
    );
  }
}
