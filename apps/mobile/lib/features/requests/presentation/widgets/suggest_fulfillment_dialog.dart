import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/post/presentation/providers/my_posts_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/suggestions_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class SuggestFulfillmentDialog extends ConsumerStatefulWidget {
  const SuggestFulfillmentDialog({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<SuggestFulfillmentDialog> createState() =>
      _SuggestFulfillmentDialogState();
}

class _SuggestFulfillmentDialogState
    extends ConsumerState<SuggestFulfillmentDialog> {
  String? _selectedPostId;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_selectedPostId == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final posts = ref.read(myPostsProvider).value ?? [];
      final post = posts.firstWhere((p) => p.id == _selectedPostId);
      final useCase = ref.read(suggestFulfillmentUseCaseProvider);
      await useCase(
        requestId: widget.requestId,
        postId: post.id,
        postTitle: post.title,
        postType: post.postType.name,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Suggestion submitted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit suggestion: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final postsAsync = ref.watch(myPostsProvider);
    final suggestionsAsync = ref.watch(suggestionsProvider(widget.requestId));
    final alreadySuggestedPostIds = (suggestionsAsync.asData?.value ?? const [])
        .map((s) => s.postId)
        .toSet();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Suggest a Fulfillment',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'LINK ONE OF YOUR POSTS',
                style: AppTypography.mono(
                  base: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ac.mutedForeground,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              postsAsync.when(
                loading: () => const SizedBox(
                  height: 42,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: ac.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load your posts. Please try again.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ac.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (posts) {
                  final availablePosts = posts
                      .where((p) => !alreadySuggestedPostIds.contains(p.id))
                      .toList();

                  final emptyMessage = posts.isEmpty
                      ? 'You have no posts yet.'
                      : 'All your posts are already suggested.';

                  if (availablePosts.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        emptyMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ac.mutedForeground,
                        ),
                      ),
                    );
                  }

                  // Clear selection if previously selected post is no longer available.
                  if (_selectedPostId != null &&
                      !availablePosts.any((p) => p.id == _selectedPostId)) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => setState(() => _selectedPostId = null),
                    );
                  }

                  return Container(
                    height: 42,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPostId,
                        isExpanded: true,
                        hint: Text(
                          'Select a post',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ac.mutedForeground,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: ac.mutedForeground,
                          size: 18,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                        items: availablePosts.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              p.title,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedPostId = v),
                        focusColor: Colors.transparent,
                        dropdownColor: cs.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _selectedPostId != null && !_isSubmitting
                        ? _submit
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.amber,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: ac.amber.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
