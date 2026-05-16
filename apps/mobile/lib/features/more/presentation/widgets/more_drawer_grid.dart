import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_tile.dart';

class MoreDrawerGrid extends StatelessWidget {
  const MoreDrawerGrid({
    super.key,
    required this.onSavedTap,
    required this.onDepartmentsTap,
    required this.onRequestsTap,
    required this.onProfileTap,
  });

  final VoidCallback onSavedTap;
  final VoidCallback onDepartmentsTap;
  final VoidCallback onRequestsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
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
    );
  }
}
