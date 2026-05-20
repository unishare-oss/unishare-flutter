import 'package:flutter/material.dart';

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
  });

  final VoidCallback onSavedTap;
  final VoidCallback onDepartmentsTap;
  final VoidCallback onRequestsTap;
  final VoidCallback onAchievementsTap;
  final bool isModerator;
  final VoidCallback? onModerationTap;

  // Tiles per row. Profile no longer lives in this grid — the user-row
  // at the top of the drawer is now tappable and serves as the profile
  // entry point. The second row is left-aligned so future destinations
  // (admin, sponsor recognition, etc.) slot in next to ACHIEVEMENTS
  // without needing recentring.
  static const _columnsPerRow = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MoreDrawerTile(
                  label: 'SAVED',
                  icon: Icons.bookmark_outline,
                  onTap: onSavedTap,
                ),
              ),
              Expanded(
                child: MoreDrawerTile(
                  label: 'DEPARTMENTS',
                  icon: Icons.apartment_outlined,
                  onTap: onDepartmentsTap,
                ),
              ),
              Expanded(
                child: MoreDrawerTile(
                  label: 'REQUESTS',
                  icon: Icons.inbox_outlined,
                  onTap: onRequestsTap,
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MoreDrawerTile(
                  label: 'ACHIEVEMENTS',
                  icon: Icons.workspace_premium_outlined,
                  onTap: onAchievementsTap,
                ),
              ),
              if (isModerator && onModerationTap != null)
                Expanded(
                  child: MoreDrawerTile(
                    label: 'MODERATION',
                    icon: Icons.shield_outlined,
                    onTap: onModerationTap!,
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
              for (var i = 2; i < _columnsPerRow; i++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}
