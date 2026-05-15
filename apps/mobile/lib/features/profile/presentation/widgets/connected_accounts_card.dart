import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class ConnectedAccountsCard extends ConsumerWidget {
  const ConnectedAccountsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;

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
          for (final row in _rowsFor(user)) ...[
            AccountRow(label: row.label, connected: row.connected),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  List<_AccountRowData> _rowsFor(AppUser? user) {
    final ids = user?.providerIds.toSet() ?? const <String>{};
    return [
      _AccountRowData(label: 'Google', connected: ids.contains('google.com')),
      _AccountRowData(
        label: 'Email & Password',
        connected: ids.contains('password'),
      ),
    ];
  }
}

class _AccountRowData {
  const _AccountRowData({required this.label, required this.connected});
  final String label;
  final bool connected;
}

class AccountRow extends StatelessWidget {
  const AccountRow({super.key, required this.label, required this.connected});
  final String label;
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
              Text(label, style: theme.textTheme.titleSmall),
              Text(
                connected ? 'Connected' : 'Not connected',
                style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
              ),
            ],
          ),
        ),
        // Link/unlink flows aren't wired yet — neutral disabled button so users
        // don't think this is interactive.
        OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
          ),
          child: Text(connected ? 'Unlink' : 'Link'),
        ),
      ],
    );
  }
}
