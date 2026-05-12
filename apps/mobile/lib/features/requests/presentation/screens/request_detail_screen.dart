import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/suggestions_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/request_card.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/suggestion_card.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/suggest_fulfillment_dialog.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

part 'request_detail_screen.g.dart';

@riverpod
Stream<ContentRequest> requestDetail(Ref ref, String requestId) {
  return ref.watch(watchRequestUseCaseProvider).call(requestId);
}

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  Future<void> _acceptSuggestion(
    WidgetRef ref,
    BuildContext context,
    ContentRequest request,
    Suggestion suggestion,
  ) async {
    try {
      await ref
          .read(acceptSuggestionUseCaseProvider)
          .call(
            requestId: request.id,
            suggestionId: suggestion.id,
            postId: suggestion.postId,
            postTitle: suggestion.postTitle,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept suggestion: $e')),
        );
      }
    }
  }

  Future<void> _removeSuggestion(
    WidgetRef ref,
    BuildContext context,
    String requestId,
    Suggestion suggestion,
  ) async {
    try {
      await ref
          .read(removeSuggestionUseCaseProvider)
          .call(requestId: requestId, suggestionId: suggestion.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove suggestion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    final requestAsync = ref.watch(requestDetailProvider(requestId));
    final suggestionsAsync = ref.watch(suggestionsProvider(requestId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Request'), leading: const BackButton()),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load request.',
            style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
          ),
        ),
        data: (request) {
          final currentUid = ref.watch(currentUserIdProvider);
          final isOwner =
              currentUid != null && currentUid == request.requesterId;

          return ListView(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: theme.dividerColor),
                ),
                elevation: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RequestCard(request: request, tappable: false),
                    if (isOwner) ...[
                      Divider(height: 1, color: theme.dividerColor),
                      _DeleteButton(requestId: requestId),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    suggestionsAsync.when(
                      loading: () => Text(
                        'SUGGESTIONS',
                        style: AppTypography.mono(
                          base: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ac.mutedForeground,
                            letterSpacing: 0.55,
                          ),
                        ),
                      ),
                      error: (_, _) => Text(
                        'SUGGESTIONS',
                        style: AppTypography.mono(
                          base: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ac.mutedForeground,
                            letterSpacing: 0.55,
                          ),
                        ),
                      ),
                      data: (suggestions) => Text(
                        'SUGGESTIONS (${suggestions.length})',
                        style: AppTypography.mono(
                          base: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ac.mutedForeground,
                            letterSpacing: 0.55,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            SuggestFulfillmentDialog(requestId: requestId),
                      ),
                      icon: Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: ac.amber,
                      ),
                      label: Text(
                        'SUGGEST',
                        style: AppTypography.mono(
                          base: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ac.amber,
                            letterSpacing: 0.55,
                          ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              suggestionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Failed to load suggestions.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ac.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (suggestions) {
                  if (suggestions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No suggestions yet. Be the first to suggest a fulfillment!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ac.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final suggestion in suggestions) ...[
                        SuggestionCard(
                          suggestion: suggestion,
                          isAccepted:
                              request.fulfilledByPostId == suggestion.postId,
                          isOwner: isOwner,
                          onAccept: isOwner
                              ? () => _acceptSuggestion(
                                  ref,
                                  context,
                                  request,
                                  suggestion,
                                )
                              : null,
                          onRemove: isOwner
                              ? () => _removeSuggestion(
                                  ref,
                                  context,
                                  requestId,
                                  suggestion,
                                )
                              : null,
                        ),
                        Divider(height: 1, color: theme.dividerColor),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeleteButton extends ConsumerStatefulWidget {
  const _DeleteButton({required this.requestId});

  final String requestId;

  @override
  ConsumerState<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends ConsumerState<_DeleteButton> {
  bool _isLoading = false;

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this request?'),
        content: const Text(
          'This action cannot be undone. The request and all its suggestions will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(deleteRequestUseCaseProvider).call(widget.requestId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete request: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: TextButton.icon(
          onPressed: _isLoading ? null : _onDelete,
          icon: Icon(
            Icons.delete_outline,
            size: 16,
            color: _isLoading ? null : ac.mutedForeground,
          ),
          label: Text(
            'DELETE',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _isLoading ? null : ac.mutedForeground,
                letterSpacing: 0.55,
              ),
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
