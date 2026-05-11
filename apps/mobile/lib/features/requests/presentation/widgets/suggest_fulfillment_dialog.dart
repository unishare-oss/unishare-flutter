import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// Minimal post summary for the dropdown.
class _PostSummary {
  const _PostSummary({
    required this.id,
    required this.title,
    required this.postType,
  });
  final String id;
  final String title;
  final String postType;
}

class SuggestFulfillmentDialog extends ConsumerStatefulWidget {
  const SuggestFulfillmentDialog({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<SuggestFulfillmentDialog> createState() =>
      _SuggestFulfillmentDialogState();
}

class _SuggestFulfillmentDialogState
    extends ConsumerState<SuggestFulfillmentDialog> {
  _PostSummary? _selectedPost;
  bool _isSubmitting = false;

  late final Future<List<_PostSummary>> _postsFuture = _fetchUserPosts();

  Future<List<_PostSummary>> _fetchUserPosts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final snap = await FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return _PostSummary(
        id: doc.id,
        title: data['title'] as String? ?? '',
        postType: data['postType'] as String? ?? '',
      );
    }).toList();
  }

  Future<void> _submit() async {
    if (_selectedPost == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(suggestFulfillmentUseCaseProvider);
      await useCase(
        requestId: widget.requestId,
        postId: _selectedPost!.id,
        postTitle: _selectedPost!.title,
        postType: _selectedPost!.postType,
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
              // Header
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
                style: GoogleFonts.firaCode(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ac.mutedForeground,
                  letterSpacing: 0.55,
                ),
              ),
              const SizedBox(height: 8),

              FutureBuilder<List<_PostSummary>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 42,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'You have no posts yet.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: ac.mutedForeground,
                        ),
                      ),
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
                      child: DropdownButton<_PostSummary>(
                        value: _selectedPost,
                        isExpanded: true,
                        hint: Text(
                          'Select a post',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: ac.mutedForeground,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: ac.mutedForeground,
                          size: 18,
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                        items: posts.map((p) {
                          return DropdownMenuItem<_PostSummary>(
                            value: p,
                            child: Text(
                              p.title,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedPost = v),
                        focusColor: Colors.transparent,
                        dropdownColor: cs.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Actions
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
                    onPressed: _selectedPost != null && !_isSubmitting
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
