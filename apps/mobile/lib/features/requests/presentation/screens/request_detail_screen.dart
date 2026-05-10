import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/suggestions_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/request_card.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/suggestion_card.dart';
import 'package:unishare_mobile/features/requests/presentation/widgets/suggest_fulfillment_dialog.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

// We need to watch the full request from the requests stream.
// For the detail screen we use a simple FutureProvider approach
// by re-using the requests provider with no filter and extracting by id.
// The easiest pattern is to pass the request as extra or fetch once.
// Per the spec, the route is /more/requests/:requestId.
// We load the request via a dedicated provider below.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unishare_mobile/features/requests/data/models/request_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'request_detail_screen.g.dart';

@riverpod
Stream<ContentRequest> requestDetail(Ref ref, String requestId) {
  return FirebaseFirestore.instance
      .collection('requests')
      .doc(requestId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) throw StateError('request_not_found');
        return RequestDto.fromJson(doc.data()!).toDomain();
      });
}

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

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
        data: (request) => ListView(
          children: [
            // Request card (non-tappable)
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: theme.dividerColor),
              ),
              elevation: 1,
              child: RequestCard(request: request, tappable: false),
            ),

            // Suggestions header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  suggestionsAsync.when(
                    loading: () => Text(
                      'SUGGESTIONS',
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ac.mutedForeground,
                        letterSpacing: 0.55,
                      ),
                    ),
                    error: (_, _) => Text(
                      'SUGGESTIONS',
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ac.mutedForeground,
                        letterSpacing: 0.55,
                      ),
                    ),
                    data: (suggestions) => Text(
                      'SUGGESTIONS (${suggestions.length})',
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ac.mutedForeground,
                        letterSpacing: 0.55,
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
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ac.amber,
                        letterSpacing: 0.55,
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

            // Suggestions list
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
                      SuggestionCard(suggestion: suggestion),
                      Divider(height: 1, color: theme.dividerColor),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
