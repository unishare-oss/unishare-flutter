import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

/// Post-type chip (NOTE / EXERCISE) shared by the pending and rejected
/// moderation cards. [postType] is the stored enum name.
class ModerationTypeChip extends StatelessWidget {
  const ModerationTypeChip({super.key, required this.postType});

  final String postType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = theme.extension<AppColors>()!;
    final type = PostType.fromName(postType);
    final isNote = type == PostType.lectureNote;
    final color = isNote ? ac.info : ac.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNote ? ac.info.withValues(alpha: 0.12) : ac.amberSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.displayLabel,
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0.55,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Outlined tag chip shared by the moderation cards.
class ModerationTagChip extends StatelessWidget {
  const ModerationTagChip({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0.55,
          ),
        ),
      ),
    );
  }
}

/// Compact relative-time label used on moderation cards.
String moderationTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) return '${diff.inHours} hours ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
  return 'just now';
}
