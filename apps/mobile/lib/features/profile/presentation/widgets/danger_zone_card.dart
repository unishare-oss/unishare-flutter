import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_typography.dart';

class DangerZoneCard extends StatelessWidget {
  const DangerZoneCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DANGER ZONE',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: cs.error,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: cs.error.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const DangerRow(
            title: 'Download my data',
            subtitle:
                'Export a copy of your personal data (PDPA right to data portability).',
            actionLabel: 'Download',
            destructive: false,
          ),
          const SizedBox(height: 16),
          const DangerRow(
            title: 'Remove encryption keys',
            subtitle:
                'Wipe your encryption keys from this device and the server.',
            actionLabel: 'Remove keys',
            destructive: true,
          ),
          const SizedBox(height: 16),
          const DangerRow(
            title: 'Delete account',
            subtitle:
                'Permanently delete your account and all associated data.',
            actionLabel: 'Delete',
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class DangerRow extends StatelessWidget {
  const DangerRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.destructive,
    this.onPressed,
  });
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool destructive;

  /// `null` keeps the row visible but clearly disabled (greyed-out).
  /// Wire a callback once the underlying flow is implemented.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Disabled destructive rows should NOT look like enabled destructive
        // buttons. Use a neutral outlined style when no action is wired.
        enabled
            ? FilledButton(
                onPressed: onPressed,
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                      )
                    : null,
                child: Text(actionLabel),
              )
            : OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(actionLabel),
              ),
      ],
    );
  }
}
