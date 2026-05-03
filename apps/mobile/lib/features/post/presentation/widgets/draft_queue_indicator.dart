import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/post_draft.dart';
import '../providers/draft_queue_provider.dart';

class DraftQueueIndicator extends ConsumerWidget {
  const DraftQueueIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(draftQueueProvider);
    final pending = queue
        .where((d) =>
            d.status == DraftStatus.queued || d.status == DraftStatus.idle)
        .length;

    if (pending == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        border: Border.all(color: const Color(0xFFE2DAD0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 13, color: Color(0xFF8A837E)),
          const SizedBox(width: 4),
          Text(
            '$pending queued',
            style: GoogleFonts.firaCode(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A837E),
            ),
          ),
        ],
      ),
    );
  }
}
