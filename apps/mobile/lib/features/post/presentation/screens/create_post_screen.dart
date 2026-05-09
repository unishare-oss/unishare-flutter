import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/post/domain/entities/code_snippet.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/course_step.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/details_step.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/draft_queue_indicator.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/files_step.dart';
import 'package:unishare_mobile/features/post/presentation/widgets/type_step.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

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
  String? _departmentId;

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
      1 => _year != null && _courseId != null && _departmentId != null,
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

  void _submit() {
    final currentState = ref.read(createPostProvider);
    if (currentState is CreatePostUploading ||
        currentState is CreatePostPublishing) {
      return;
    }

    final localMediaPaths = _pickedFiles
        .map((f) => f.bytes != null ? f.name : f.path!)
        .toList();

    final fileDataOverride = {
      for (final f in _pickedFiles)
        if (f.bytes != null) f.name: f.bytes!,
    };

    final draft = PostDraft(
      id: CreatePostNotifier.generateId(),
      postType: _postType ?? PostType.lectureNote,
      year: _year ?? 1,
      courseId: _courseId ?? '',
      departmentId: _departmentId ?? '',
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

    final wasIdle = ref.read(createPostProvider) is CreatePostIdle;
    ref
        .read(createPostProvider.notifier)
        .submit(
          draft: draft,
          fileDataOverride: fileDataOverride.isEmpty ? null : fileDataOverride,
        );
    if (wasIdle) {
      final newState = ref.read(createPostProvider);
      if (newState is CreatePostUploading || newState is CreatePostPublishing) {
        context.push('/upload-progress');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final dividerColor = Theme.of(context).dividerColor;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          'New Post',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: dividerColor),
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
                    child: Center(child: _StepIndicator(currentStep: _step)),
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
                            universityId:
                                ref
                                    .watch(currentUserProvider)
                                    .value
                                    ?.universityId ??
                                '',
                            selectedDepartmentId: _departmentId,
                            selectedYear: _year,
                            selectedCourseId: _courseId,
                            onDepartmentChanged: (d) => setState(() {
                              _departmentId = d;
                              _year = null;
                              _courseId = null;
                            }),
                            onYearChanged: (y) => setState(() {
                              _year = y;
                              _courseId = null;
                            }),
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
              ],
            ),
          ),

          // StepNav bar
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const DraftQueueIndicator(),
                const Spacer(),
                // Back button
                TextButton(
                  onPressed: _goBack,
                  style: TextButton.styleFrom(
                    foregroundColor: ac.mutedForeground,
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
                    onPressed: _nextEnabled ? _goNext : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.amber,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      disabledBackgroundColor: ac.amber.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      _step == 3 ? 'Submit' : 'Next',
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
    final ac = Theme.of(context).extension<AppColors>()!;
    final dividerColor = Theme.of(context).dividerColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 4; i++) ...[
          _StepDot(
            number: i + 1,
            isCompleted: i < currentStep,
            isActive: i == currentStep,
          ),
          if (i < 3)
            Container(
              width: 56,
              height: 1,
              color: i < currentStep ? ac.amber : dividerColor,
            ),
        ],
      ],
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
    final ac = Theme.of(context).extension<AppColors>()!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color bg;
    final Widget child;

    if (isCompleted) {
      bg = ac.amber;
      child = Icon(
        Icons.check,
        size: 13,
        color: Theme.of(context).colorScheme.surface,
      );
    } else if (isActive) {
      bg = ac.amber;
      child = Text(
        '$number',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.surface,
        ),
      );
    } else {
      bg = scaffoldBg;
      child = Text(
        '$number',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ac.mutedForeground,
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
