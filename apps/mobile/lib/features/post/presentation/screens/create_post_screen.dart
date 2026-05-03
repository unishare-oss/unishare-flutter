import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/create_post_provider.dart';
import '../widgets/draft_queue_indicator.dart';
import '../widgets/media_attachment_picker.dart';

const _kBg = Colors.white;
const _kBorder = Color(0xFFE2DAD0);
const _kPrimary = Color(0xFFD97706);
const _kFg = Color(0xFF1C1917);
const _kMuted = Color(0xFF8A837E);
const _kFill = Color(0xFFFEF3C7);
const _kDestructive = Color(0xFFDC2626);

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _tags = <String>[];
  final _mediaPaths = <String>[];
  bool _titleEmpty = true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(createPostProvider);

    ref.listen<CreatePostState>(createPostProvider, (_, next) {
      if (next is CreatePostPublished) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published!')),
        );
        context.pop();
        ref.read(createPostProvider.notifier).reset();
      }
    });

    final isSubmitting =
        postState is CreatePostUploading || postState is CreatePostPublishing;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kFg),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create post',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kFg,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (postState is CreatePostUploading) ...[
                    LinearProgressIndicator(
                      value: postState.progress,
                      backgroundColor: _kBorder,
                      valueColor: const AlwaysStoppedAnimation(_kPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploading ${(postState.progress * 100).toInt()}%…',
                      style: GoogleFonts.firaCode(fontSize: 12, color: _kMuted),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (postState is CreatePostPublishing) ...[
                    const LinearProgressIndicator(
                      backgroundColor: _kBorder,
                      valueColor: AlwaysStoppedAnimation(_kPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Publishing…',
                      style: GoogleFonts.firaCode(fontSize: 12, color: _kMuted),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (postState is CreatePostQueued) ...[
                    _Banner(
                      message:
                          'Saved offline — will publish when you reconnect.',
                      bg: const Color(0xFFF7F3EE),
                      fg: _kMuted,
                      border: _kBorder,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (postState is CreatePostError) ...[
                    _Banner(
                      message: postState.message == 'title_required'
                          ? 'Title is required.'
                          : postState.message,
                      bg: const Color(0xFFFEF2F2),
                      fg: _kDestructive,
                      border: _kDestructive,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _Label('Title'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleCtrl,
                    enabled: !isSubmitting,
                    onChanged: (v) =>
                        setState(() => _titleEmpty = v.trim().isEmpty),
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, color: _kFg),
                    decoration: _dec('Enter a title…'),
                  ),
                  const SizedBox(height: 16),
                  _Label('Body'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bodyCtrl,
                    enabled: !isSubmitting,
                    maxLines: 6,
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, color: _kFg),
                    decoration: _dec('Write something…'),
                  ),
                  const SizedBox(height: 16),
                  _Label('Tags'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tagCtrl,
                          enabled: !isSubmitting,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.firaCode(
                              fontSize: 13, color: _kFg),
                          decoration: _dec('Add a tag…'),
                          onFieldSubmitted: _addTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: isSubmitting
                            ? null
                            : () => _addTag(_tagCtrl.text),
                        icon: const Icon(Icons.add, color: _kPrimary),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _tags
                          .map((t) => _TagChip(
                                label: t,
                                onDelete: isSubmitting
                                    ? null
                                    : () =>
                                        setState(() => _tags.remove(t)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _Label('Attachments'),
                  const SizedBox(height: 6),
                  MediaAttachmentPicker(
                    paths: _mediaPaths,
                    enabled: !isSubmitting,
                    onChanged: (paths) => setState(() {
                      _mediaPaths
                        ..clear()
                        ..addAll(paths);
                    }),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const DraftQueueIndicator(),
                const Spacer(),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed:
                        (!_titleEmpty && !isSubmitting) ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _kPrimary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      isSubmitting ? 'Publishing…' : 'Publish',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addTag(String value) {
    final tag = value.trim().replaceAll('#', '');
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() => _tags.add(tag));
    _tagCtrl.clear();
  }

  Future<void> _submit() async {
    await ref.read(createPostProvider.notifier).submit(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          tags: List.from(_tags),
          localMediaPaths: List.from(_mediaPaths),
        );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.spaceGrotesk(fontSize: 14, color: _kMuted),
        filled: true,
        fillColor: _kFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: _kPrimary, width: 1.5),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1C1917),
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.bg,
    required this.fg,
    required this.border,
  });
  final String message;
  final Color bg, fg, border;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border.withValues(alpha: 0.4)),
        ),
        child: Text(
          message,
          style: GoogleFonts.spaceGrotesk(fontSize: 13, color: fg),
        ),
      );
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.onDelete});
  final String label;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EE),
          border: Border.all(color: const Color(0xFFE2DAD0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$label',
              style: GoogleFonts.firaCode(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8A837E),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    size: 14, color: Color(0xFF8A837E)),
              ),
            ],
          ],
        ),
      );
}
