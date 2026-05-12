import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m minute${m == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hour${h == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) {
    final d = diff.inDays;
    return '$d day${d == 1 ? '' : 's'} ago';
  }
  final months = (diff.inDays / 30).floor();
  return '$months month${months == 1 ? '' : 's'} ago';
}

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({super.key, required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  suggestion.postTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ac.muted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  suggestion.postType.toUpperCase(),
                  style: AppTypography.mono(
                    base: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ac.mutedForeground,
                      letterSpacing: 0.55,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (suggestion.suggestedByAvatar != null &&
                  suggestion.suggestedByAvatar!.isNotEmpty)
                CircleAvatar(
                  radius: 10,
                  backgroundImage: CachedNetworkImageProvider(
                    suggestion.suggestedByAvatar!,
                  ),
                )
              else
                CircleAvatar(
                  radius: 10,
                  backgroundColor: ac.muted,
                  child: Icon(
                    Icons.person,
                    size: 12,
                    color: ac.mutedForeground,
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Suggested by ${suggestion.suggestedByName} · ${_timeAgo(suggestion.createdAt)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ac.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
