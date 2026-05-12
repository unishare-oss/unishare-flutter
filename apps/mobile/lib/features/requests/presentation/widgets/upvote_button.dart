import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/requests/presentation/providers/upvote_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class UpvoteButton extends ConsumerWidget {
  const UpvoteButton({
    super.key,
    required this.requestId,
    required this.upvoteCount,
  });

  final String requestId;
  final int upvoteCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final hasUpvotedAsync = ref.watch(hasUpvotedProvider(requestId));
    final toggleState = ref.watch(toggleUpvoteProvider(requestId));

    final isActive = hasUpvotedAsync.asData?.value ?? false;
    final isLoading = toggleState.isLoading;

    return Semantics(
      label: 'Upvote',
      button: true,
      child: InkWell(
        onTap: isLoading
            ? null
            : () => ref.read(toggleUpvoteProvider(requestId).notifier).toggle(),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: isActive ? ac.amber : ac.mutedForeground,
                size: 20,
              ),
              Text(
                '$upvoteCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? ac.amber : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
