import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

class FeedEmptyStateWidget extends StatelessWidget {
  const FeedEmptyStateWidget({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off, size: 48, color: ac.mutedForeground),
            const SizedBox(height: 16),
            Text(
              'No posts match your filter',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting different tags or clear the filter to see all posts.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ac.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: ac.amber,
                side: BorderSide(color: ac.amber),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear filter'),
            ),
          ],
        ),
      ),
    );
  }
}
