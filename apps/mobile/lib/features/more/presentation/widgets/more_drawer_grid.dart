import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_tile.dart';

class MoreDrawerGrid extends StatelessWidget {
  const MoreDrawerGrid({
    super.key,
    required this.onSavedTap,
    required this.onDepartmentsTap,
    required this.onRequestsTap,
    required this.onProfileTap,
    required this.onAchievementsTap,
  });

  final VoidCallback onSavedTap;
  final VoidCallback onDepartmentsTap;
  final VoidCallback onRequestsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onAchievementsTap;

  @override
  Widget build(BuildContext context) {
    // Five tiles split across two rows: the original four destinations
    // up top, the new Achievements destination centred below. Keeps
    // each tile at the same width/height as before so the visual
    // weight of the existing destinations doesn't shrink.
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
              Expanded(
                child: MoreDrawerTile(
                  label: 'PROFILE',
                  icon: Icons.settings_outlined,
                  onTap: onProfileTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              Expanded(
                child: MoreDrawerTile(
                  label: 'ACHIEVEMENTS',
                  icon: Icons.workspace_premium_outlined,
                  onTap: onAchievementsTap,
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
