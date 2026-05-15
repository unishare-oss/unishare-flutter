import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class ConnectedAccountsCard extends StatelessWidget {
  const ConnectedAccountsCard({super.key});

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
            'CONNECTED ACCOUNTS',
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
          const SizedBox(height: 12),
          const AccountRow(provider: 'Google', connected: true),
          const SizedBox(height: 12),
          const AccountRow(provider: 'Microsoft', connected: false),
        ],
      ),
    );
  }
}

class AccountRow extends StatelessWidget {
  const AccountRow({
    super.key,
    required this.provider,
    required this.connected,
  });
  final String provider;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider, style: theme.textTheme.titleSmall),
              if (connected)
                Text(
                  'Connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ac.textMuted,
                  ),
                ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: null,
          child: Text(connected ? 'Unlink' : 'Link'),
        ),
      ],
    );
  }
}
