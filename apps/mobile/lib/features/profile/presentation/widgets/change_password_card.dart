import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/profile/presentation/widgets/profile_field_label.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class ChangePasswordCard extends StatelessWidget {
  const ChangePasswordCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHANGE PASSWORD',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),
          const ProfileFieldLabel('CURRENT PASSWORD'),
          const SizedBox(height: 6),
          const TextField(obscureText: true, decoration: InputDecoration()),
          const SizedBox(height: 16),
          const ProfileFieldLabel('NEW PASSWORD'),
          const SizedBox(height: 6),
          const TextField(obscureText: true, decoration: InputDecoration()),
          const SizedBox(height: 16),
          const ProfileFieldLabel('CONFIRM NEW PASSWORD'),
          const SizedBox(height: 6),
          const TextField(obscureText: true, decoration: InputDecoration()),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: ac.amber,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ac.amber.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
              ),
              child: const Text('Change Password'),
            ),
          ),
        ],
      ),
    );
  }
}
