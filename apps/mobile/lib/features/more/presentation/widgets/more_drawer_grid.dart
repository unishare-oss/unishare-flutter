import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_tile.dart';

class MoreDrawerGrid extends StatelessWidget {
  const MoreDrawerGrid({
    super.key,
    required this.onSavedTap,
    required this.onDepartmentsTap,
    required this.onRequestsTap,
    required this.onAchievementsTap,
    this.isModerator = false,
    this.onModerationTap,
    this.isAdmin = false,
    this.onAdminUsersTap,
    this.onAdminDepartmentsTap,
  });

  final VoidCallback onSavedTap;
  final VoidCallback onDepartmentsTap;
  final VoidCallback onRequestsTap;
  final VoidCallback onAchievementsTap;

  /// Moderation access (moderators and admins). Surfaces the MODERATION tile
  /// in the staff section.
  final bool isModerator;
  final VoidCallback? onModerationTap;

  /// Full admin access. Surfaces DEPTS + USERS in the staff section.
  final bool isAdmin;
  final VoidCallback? onAdminUsersTap;
  final VoidCallback? onAdminDepartmentsTap;

  // 3-column grid — tiles fill left-to-right; a short final row stays
  // left-aligned (matching the design), with empty cells padding the row so
  // columns line up instead of stretching across the full width.
  static const _columnsPerRow = 3;

  @override
  Widget build(BuildContext context) {
    final general = <MoreDrawerTile>[
      MoreDrawerTile(
        label: 'SAVED',
        icon: Icons.bookmark_outline,
        onTap: onSavedTap,
      ),
      MoreDrawerTile(
        label: 'DEPARTMENTS',
        icon: Icons.apartment_outlined,
        onTap: onDepartmentsTap,
      ),
      MoreDrawerTile(
        label: 'REQUESTS',
        icon: Icons.inbox_outlined,
        onTap: onRequestsTap,
      ),
      MoreDrawerTile(
        label: 'ACHIEVEMENTS',
        icon: Icons.workspace_premium_outlined,
        onTap: onAchievementsTap,
      ),
    ];

    final staff = <MoreDrawerTile>[
      if (isModerator && onModerationTap != null)
        MoreDrawerTile(
          label: 'MODERATION',
          icon: Icons.shield_outlined,
          onTap: onModerationTap!,
        ),
      if (isAdmin && onAdminDepartmentsTap != null)
        MoreDrawerTile(
          label: 'DEPTS',
          icon: Icons.apartment_outlined,
          onTap: onAdminDepartmentsTap!,
        ),
      if (isAdmin && onAdminUsersTap != null)
        MoreDrawerTile(
          label: 'USERS',
          icon: Icons.people_outline,
          onTap: onAdminUsersTap!,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _grid(general),
          if (staff.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel('ADMIN'),
            const SizedBox(height: 12),
            _grid(staff),
          ],
        ],
      ),
    );
  }

  /// Lays [tiles] into rows of [_columnsPerRow] equal columns. Trailing gaps
  /// in the last row are filled with empty cells so the grid stays aligned.
  Widget _grid(List<MoreDrawerTile> tiles) {
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += _columnsPerRow) {
      final cells = <Widget>[
        for (var col = 0; col < _columnsPerRow; col++)
          Expanded(
            child: start + col < tiles.length
                ? tiles[start + col]
                : const SizedBox.shrink(),
          ),
      ];
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
      rows.add(Row(children: cells));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// Left-aligned muted section header (e.g. "ADMIN"), matching the mono tile
/// labels' treatment.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w700,
            color: ac.textMuted,
          ),
        ),
      ),
    );
  }
}
