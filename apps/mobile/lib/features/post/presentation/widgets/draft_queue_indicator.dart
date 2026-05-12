import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/draft_queue_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class DraftQueueIndicator extends ConsumerWidget {
  const DraftQueueIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(draftQueueProvider);
    final pending = queue
        .where(
          (d) => d.status == DraftStatus.queued || d.status == DraftStatus.idle,
        )
        .length;

    if (pending == 0) return const SizedBox.shrink();

    final ac = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 13, color: ac.textMuted),
          const SizedBox(width: 4),
          Text(
            '$pending queued',
            style: AppTypography.mono(
              base: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ac.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
