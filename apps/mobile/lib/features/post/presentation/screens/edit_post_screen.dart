import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/providers/edit_post_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  const EditPostScreen({super.key, required this.postId, this.post});

  final String postId;
  final Post? post;

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _moduleCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _tagCtrl;
  late List<String> _tags;
  late String _originalDescription;

  String? _titleError;
  String? _descError;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _moduleCtrl = TextEditingController(text: p?.moduleNumber ?? '');
    _urlCtrl = TextEditingController(text: p?.externalUrl ?? '');
    _tagCtrl = TextEditingController();
    _tags = List<String>.from(p?.tags ?? []);
    _originalDescription = p?.description ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _moduleCtrl.dispose();
    _urlCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim().replaceAll('#', '');
    if (tag.isEmpty || _tags.contains(tag) || _tags.length >= 5) {
      _tagCtrl.clear();
      return;
    }
    setState(() => _tags.add(tag));
    _tagCtrl.clear();
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    setState(() {
      _titleError = title.isEmpty ? 'Title is required' : null;
      _descError = desc.isEmpty ? 'Description is required' : null;
    });
    if (title.isEmpty || desc.isEmpty) return;

    final post = widget.post;
    await ref.read(editPostProvider.notifier).save(
      postId: widget.postId,
      title: title,
      description: desc,
      tags: _tags,
      externalUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      moduleNumber: _moduleCtrl.text.trim(),
      descriptionChanged: desc != _originalDescription,
      currentSummaryStatus: post?.summaryStatus,
    );

    if (!mounted) return;
    final state = ref.read(editPostProvider);
    if (state is AsyncData) {
      context.pop();
    } else if (state is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${state.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    if (post == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isLoading = ref.watch(editPostProvider).isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: cs.onSurface),
        title: Text('Edit Post', style: theme.textTheme.titleMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: isLoading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: ac.amber,
                foregroundColor: cs.onPrimary,
                disabledBackgroundColor: ac.amber.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(
                      'Save',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Read-only context info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ac.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: ac.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '${post.courseId} · Year ${post.year} · Sem ${post.semester}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ac.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text('Title', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: InputDecoration(
                hintText: 'Enter title',
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text('Description', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              minLines: 3,
              onChanged: (_) {
                if (_descError != null) setState(() => _descError = null);
              },
              decoration: InputDecoration(
                hintText: 'Enter description',
                errorText: _descError,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Module number
            Text('Module number', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _moduleCtrl,
              decoration: const InputDecoration(hintText: 'e.g. 3'),
            ),
            const SizedBox(height: 16),

            // External URL
            Text('External URL (optional)', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(hintText: 'https://...'),
            ),
            const SizedBox(height: 16),

            // Tags
            Text('Tags (max 5)', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags
                    .map(
                      (t) => Chip(
                        label: Text(t, style: theme.textTheme.labelSmall),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeTag(t),
                        backgroundColor: ac.muted,
                        side: BorderSide(color: theme.dividerColor),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (_tags.length < 5)
              TextField(
                controller: _tagCtrl,
                decoration: InputDecoration(
                  hintText: 'Add tag and press Enter',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_tagCtrl.text),
                  ),
                ),
                onSubmitted: _addTag,
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
