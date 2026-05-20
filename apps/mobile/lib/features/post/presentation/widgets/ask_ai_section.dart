import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';
import 'package:unishare_mobile/features/post/domain/repositories/ask_ai_repository.dart';
import 'package:unishare_mobile/features/post/presentation/providers/ask_ai_provider.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/ai_message_bubble.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class AskAiSection extends ConsumerStatefulWidget {
  const AskAiSection({
    super.key,
    required this.postId,
    required this.summary,
    this.extractedText,
  });

  final String postId;
  final String summary;

  /// PROP-0011 Phase 3 — when present, used as the worker's grounding context
  /// instead of [summary], so answers can reference details beyond the
  /// 3-7 bullet summary. Null for posts created before extractedText was cached.
  final String? extractedText;

  @override
  ConsumerState<AskAiSection> createState() => _AskAiSectionState();
}

class _AskAiSectionState extends ConsumerState<AskAiSection> {
  bool _expanded = false;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    _controller.clear();
    try {
      await ref
          .read(askAiProvider(widget.postId).notifier)
          .sendMessage(
            question,
            summary: widget.summary,
            extractedText: widget.extractedText,
          );
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } on AskAiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final messages = ref.watch(askAiProvider(widget.postId)).value ?? [];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ac.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ac, theme),
          if (_expanded) ...[
            Divider(height: 1, color: theme.dividerColor),
            _buildMessageList(context, ac, theme, cs, messages),
            _buildInput(context, ac, cs, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors ac, ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(8),
        bottom: _expanded ? Radius.zero : const Radius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.smart_toy_outlined, size: 13, color: ac.info),
            const SizedBox(width: 6),
            Text(
              'ASK AI',
              style: AppTypography.mono(
                base: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ac.info,
                  letterSpacing: 0.6,
                  fontSize: 11,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: ac.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    AppColors ac,
    ThemeData theme,
    ColorScheme cs,
    List<AiMessage> messages,
  ) {
    if (messages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          'Ask anything about this document…',
          style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) =>
            AiMessageBubble(message: messages[index]),
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    AppColors ac,
    ColorScheme cs,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: 500,
              // Cap at 5 so pasted/long input scrolls internally rather
              // than growing the input bar.
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask a question…',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: ac.textMuted,
                ),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _send,
            icon: const Icon(Icons.send, size: 18),
            color: ac.amber,
            style: IconButton.styleFrom(
              backgroundColor: ac.amberSubtle,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}
