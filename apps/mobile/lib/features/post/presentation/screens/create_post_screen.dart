import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/domain/entities/code_snippet.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/course_step.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/details_step.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/draft_queue_indicator.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/files_step.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/type_step.dart';

const _kBg = Color(0xFFF7F3EE);
const _kWhite = Colors.white;
const _kPrimary = Color(0xFFD97706);
const _kBorder = Color(0xFFE2DAD0);
const _kFg = Color(0xFF1C1917);
const _kMuted = Color(0xFF8A837E);
const _kDestructive = Color(0xFFDC2626);

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _pageCtrl = PageController();
  int _step = 0; // 0-indexed

  // Step 1
  PostType? _postType;

  // Step 2
  int? _year;
  String? _courseId;

  // Step 3
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  PostingIdentity _postingIdentity = PostingIdentity.named;
  int _semester = 1;
  final _tags = <String>[];

  // Step 4
  final _pickedFiles = <PlatformFile>[];
  CodeSnippet? _codeSnippet;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_rebuild);
    _descCtrl.addListener(_rebuild);
    _moduleCtrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.removeListener(_rebuild);
    _descCtrl.removeListener(_rebuild);
    _moduleCtrl.removeListener(_rebuild);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _moduleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  bool get _nextEnabled {
    return switch (_step) {
      0 => _postType != null,
      1 => _year != null && _courseId != null,
      2 =>
        _titleCtrl.text.trim().isNotEmpty &&
            _descCtrl.text.trim().isNotEmpty &&
            _moduleCtrl.text.trim().isNotEmpty,
      3 => true, // Submit always enabled on step 4
      _ => false,
    };
  }

  void _goNext() {
    if (_step < 3) {
      setState(() => _step++);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Use Navigator.maybePop so the wizard does not crash in contexts
      // without a GoRouter (e.g. widget tests, deep-link entry points).
      // If nothing pops we simply stay — the user can close via OS gesture.
      Navigator.maybePop(context);
    }
  }

  Future<void> _submit() async {
    // On mobile use f.path (full filesystem path needed to read the file).
    // On web use f.name — f.path is a blob URL which breaks content-type
    // detection and doesn't help with file reading (bytes are in f.bytes).
    final localMediaPaths =
        _pickedFiles.map((f) => f.bytes != null ? f.name : f.path!).toList();

    // Bytes populated on web (withData: kIsWeb). Key matches localMediaPaths.
    final fileDataOverride = {
      for (final f in _pickedFiles)
        if (f.bytes != null) f.name: f.bytes!,
    };

    final draft = PostDraft(
      id: CreatePostNotifier.generateId(),
      postType: _postType ?? PostType.lectureNote,
      year: _year ?? 1,
      courseId: _courseId ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      postingIdentity: _postingIdentity,
      semester: _semester,
      moduleNumber: _moduleCtrl.text.trim(),
      externalUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      tags: List.from(_tags),
      localMediaPaths: localMediaPaths,
      uploadedUrls: {},
      codeSnippet: _codeSnippet,
      createdAt: DateTime.now(),
    );

    await ref
        .read(createPostProvider.notifier)
        .submit(
          draft: draft,
          fileDataOverride: fileDataOverride.isEmpty ? null : fileDataOverride,
        );
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(createPostProvider);

    ref.listen<CreatePostState>(createPostProvider, (_, next) {
      if (next is CreatePostPublished) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post published!')));
        if (context.canPop()) context.pop(); else context.go('/feed');
        ref.read(createPostProvider.notifier).reset();
      } else if (next is CreatePostQueued) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved offline — will publish when you reconnect.'),
          ),
        );
        if (context.canPop()) context.pop(); else context.go('/feed');
        ref.read(createPostProvider.notifier).reset();
      }
    });

    final isSubmitting =
        postState is CreatePostUploading || postState is CreatePostPublishing;

    return Scaffold(
      backgroundColor: _kWhite,
      appBar: AppBar(
        backgroundColor: _kWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          'New Post',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kFg,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Column(
        children: [
          // Step indicator + scrollable step content
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _StepIndicator(currentStep: _step),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    child: SizedBox(
                      // Fixed height PageView so steps can be any length.
                      // The CustomScrollView handles overflow with scroll.
                      height: _stepHeight,
                      child: PageView(
                        controller: _pageCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          TypeStep(
                            selected: _postType,
                            onSelect: (t) => setState(() => _postType = t),
                          ),
                          CourseStep(
                            selectedYear: _year,
                            selectedCourseId: _courseId,
                            onYearChanged: (y) => setState(() => _year = y),
                            onCourseChanged: (c) =>
                                setState(() => _courseId = c),
                          ),
                          DetailsStep(
                            titleController: _titleCtrl,
                            descriptionController: _descCtrl,
                            moduleNumberController: _moduleCtrl,
                            externalUrlController: _urlCtrl,
                            postingIdentity: _postingIdentity,
                            semester: _semester,
                            tags: _tags,
                            onIdentityChanged: (v) =>
                                setState(() => _postingIdentity = v),
                            onSemesterChanged: (v) =>
                                setState(() => _semester = v),
                            onTagsChanged: (v) => setState(() {
                              _tags
                                ..clear()
                                ..addAll(v);
                            }),
                          ),
                          FilesStep(
                            files: _pickedFiles,
                            codeSnippet: _codeSnippet,
                            onFilesChanged: (files) => setState(() {
                              _pickedFiles
                                ..clear()
                                ..addAll(files);
                            }),
                            onSnippetChanged: (s) =>
                                setState(() => _codeSnippet = s),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Error / status banners
                if (postState is CreatePostError)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _Banner(
                        message: _errorMessage(postState.message),
                        bg: const Color(0xFFFEF2F2),
                        fg: _kDestructive,
                        border: _kDestructive,
                      ),
                    ),
                  ),
                if (postState is CreatePostUploading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: postState.progress,
                            backgroundColor: _kBorder,
                            valueColor: const AlwaysStoppedAnimation(_kPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uploading ${(postState.progress * 100).toInt()}%…',
                            style: GoogleFonts.firaCode(
                              fontSize: 12,
                              color: _kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (postState is CreatePostPublishing)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LinearProgressIndicator(
                            backgroundColor: _kBorder,
                            valueColor: AlwaysStoppedAnimation(_kPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Publishing…',
                            style: GoogleFonts.firaCode(
                              fontSize: 12,
                              color: _kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // StepNav bar
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const DraftQueueIndicator(),
                const Spacer(),
                // Back button
                TextButton(
                  onPressed: isSubmitting ? null : _goBack,
                  style: TextButton.styleFrom(
                    foregroundColor: _kMuted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Next / Submit button
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: (_nextEnabled && !isSubmitting) ? _goNext : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      isSubmitting
                          ? 'Publishing…'
                          : (_step == 3 ? 'Submit' : 'Next'),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

  String _errorMessage(String code) {
    return switch (code) {
      'title_required' => 'Title is required.',
      'description_required' => 'Description is required.',
      'module_required' => 'Module number is required.',
      'file_too_large' => 'One or more files exceed 50 MB.',
      _ => code,
    };
  }

  double get _stepHeight => MediaQuery.sizeOf(context).height * 1.1;
}

// ---------------------------------------------------------------------------
// StepIndicator
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep; // 0-indexed

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final isCompleted = i < currentStep;
        final isActive = i == currentStep;
        final connectLine = i < 3;

        return Expanded(
          child: Row(
            children: [
              _StepDot(
                number: i + 1,
                isCompleted: isCompleted,
                isActive: isActive,
              ),
              if (connectLine)
                Expanded(
                  child: Container(
                    height: 1,
                    color: isCompleted ? _kPrimary : _kBorder,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.isCompleted,
    required this.isActive,
  });

  final int number;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget child;

    if (isCompleted) {
      bg = _kPrimary;
      child = const Icon(Icons.check, size: 13, color: Colors.white);
    } else if (isActive) {
      bg = _kPrimary;
      child = Text(
        '$number',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );
    } else {
      bg = _kBg;
      child = Text(
        '$number',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _kMuted,
        ),
      );
    }

    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Banner
// ---------------------------------------------------------------------------

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
    margin: const EdgeInsets.only(bottom: 12),
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
