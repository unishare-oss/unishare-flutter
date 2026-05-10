import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/upvote_button.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

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

class RequestCard extends ConsumerWidget {
  const RequestCard({super.key, required this.request, this.tappable = true});

  final ContentRequest request;

  /// When [false], the card is not wrapped in an InkWell (use in detail screen).
  final bool tappable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: upvote button
          UpvoteButton(requestId: request.id, upvoteCount: request.upvoteCount),
          const SizedBox(width: 12),
          // Right: content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      request.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    _StatusChip(status: request.status),
                    _CourseChip(courseName: request.courseName),
                  ],
                ),
                // Description
                if (request.description != null &&
                    request.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ac.textMuted,
                    ),
                  ),
                ],
                // Fulfilled by link
                if (request.status == RequestStatus.fulfilled &&
                    request.fulfilledByPostId != null &&
                    request.fulfilledByPostTitle != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () =>
                        context.push('/posts/${request.fulfilledByPostId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: ac.amber,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Fulfilled by: ${request.fulfilledByPostTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ac.amber,
                              fontFamily: GoogleFonts.firaCode().fontFamily,
                              letterSpacing: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Meta row
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (request.requesterAvatar != null &&
                        request.requesterAvatar!.isNotEmpty)
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: CachedNetworkImageProvider(
                          request.requesterAvatar!,
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
                        '${request.requesterName} · ${_timeAgo(request.createdAt)}',
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
          ),
        ],
      ),
    );

    if (!tappable) return card;

    return Semantics(
      label: 'View request: ${request.title}',
      button: true,
      child: InkWell(
        onTap: () => context.push('/more/requests/${request.id}'),
        child: card,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final isFulfilled = status == RequestStatus.fulfilled;
    final bg = isFulfilled
        ? ac.success.withValues(alpha: 0.15)
        : ac.amber.withValues(alpha: 0.15);
    final fg = isFulfilled ? ac.success : ac.amber;
    final label = isFulfilled ? 'FULFILLED' : 'OPEN';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.firaCode(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.55,
        ),
      ),
    );
  }
}

class _CourseChip extends StatelessWidget {
  const _CourseChip({required this.courseName});
  final String courseName;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ac.muted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        courseName.toUpperCase(),
        style: GoogleFonts.firaCode(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ac.mutedForeground,
          letterSpacing: 0.55,
        ),
      ),
    );
  }
}
