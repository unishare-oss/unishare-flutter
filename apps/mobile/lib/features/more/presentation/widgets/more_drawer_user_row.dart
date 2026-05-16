import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_card.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class MoreDrawerUserRow extends StatelessWidget {
  const MoreDrawerUserRow({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: ac.amber, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _initials(user.name),
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                ProfileBadge(user.role.toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final solo = parts[0];
    return solo.length >= 2
        ? solo.substring(0, 2).toUpperCase()
        : solo.toUpperCase();
  }
}
