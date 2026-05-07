import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';

const _kWhite = Colors.white;
const _kBg = Color(0xFFF7F3EE);
const _kPrimary = Color(0xFFD97706);
const _kBorder = Color(0xFFE2DAD0);
const _kFg = Color(0xFF1C1917);
const _kMuted = Color(0xFF8A837E);
const _kGreen = Color(0xFF059669);
const _kGreenBg = Color(0xFFD1FAE5);
const _kDestructive = Color(0xFFDC2626);
const _kDestructiveBg = Color(0xFFFEE2E2);

class UploadProgressScreen extends ConsumerStatefulWidget {
  const UploadProgressScreen({super.key});

  @override
  ConsumerState<UploadProgressScreen> createState() =>
      _UploadProgressScreenState();
}

class _UploadProgressScreenState extends ConsumerState<UploadProgressScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<CreatePostState>(createPostProvider, (_, next) {
      if (next is CreatePostPublished) {
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          ref.read(createPostProvider.notifier).reset();
          router.go('/feed');
        });
      } else if (next is CreatePostQueued) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved offline — will publish when you reconnect.'),
            ),
          );
          context.go('/feed');
          ref.read(createPostProvider.notifier).reset();
        });
      }
    });

    final state = ref.watch(createPostProvider);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(state),
      body: SafeArea(child: _buildBody(state)),
    );
  }

  AppBar _buildAppBar(CreatePostState state) {
    final isPublishing = state is CreatePostPublishing;
    return AppBar(
      backgroundColor: _kWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Text(
        'Uploading Post',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _kFg,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: isPublishing
                ? null
                : () async {
                    await ref.read(createPostProvider.notifier).cancel();
                    if (mounted) context.go('/feed');
                  },
            style: TextButton.styleFrom(
              foregroundColor: _kDestructive,
              disabledForegroundColor: _kMuted,
              side: BorderSide(
                color: isPublishing ? _kBorder : const Color(0xFFFCA5A5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  Widget _buildBody(CreatePostState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          _buildRing(state),
          const SizedBox(height: 12),
          _buildSubtitles(state),
          const SizedBox(height: 28),
          if (state is CreatePostUploading) _buildFileList(state.files),
          if (state is CreatePostPublishing) _buildFileListAllDone(),
          if (state is CreatePostError) ...[
            _buildErrorBanner(state),
            const SizedBox(height: 16),
            _buildRetryButton(state),
          ],
        ],
      ),
    );
  }

  Widget _buildRing(CreatePostState state) {
    final Color ringColor;
    final Color ringBg;
    final Widget center;

    if (state is CreatePostUploading) {
      ringColor = _kPrimary;
      ringBg = _kBorder;
      final pct = (state.overallProgress * 100).toInt();
      center = Text(
        '$pct%',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      );
    } else if (state is CreatePostPublishing) {
      ringColor = _kGreen;
      ringBg = _kGreenBg;
      center = const Icon(Icons.check_rounded, size: 32, color: _kGreen);
    } else if (state is CreatePostError) {
      ringColor = _kDestructive;
      ringBg = _kDestructiveBg;
      center = const Icon(
        Icons.priority_high_rounded,
        size: 32,
        color: _kDestructive,
      );
    } else {
      ringColor = _kPrimary;
      ringBg = _kBorder;
      center = const SizedBox.shrink();
    }

    final double value;
    if (state is CreatePostUploading) {
      value = state.overallProgress;
    } else if (state is CreatePostError) {
      value = state.overallProgress;
    } else {
      value = 1.0;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 10,
            backgroundColor: ringBg,
            valueColor: AlwaysStoppedAnimation(ringColor),
          ),
        ),
        center,
      ],
    );
  }

  Widget _buildSubtitles(CreatePostState state) {
    if (state is CreatePostUploading) {
      final uploading = state.files
          .where((f) => f.phase == FileUploadPhase.uploading)
          .map((f) => f.filename)
          .firstOrNull;
      final done = state.files
          .where((f) => f.phase == FileUploadPhase.done)
          .length;
      final total = state.files.length;
      return Column(
        children: [
          Text(
            '$done of $total files',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kFg,
            ),
          ),
          if (uploading != null) ...[
            const SizedBox(height: 4),
            Text(
              'Uploading $uploading…',
              style: GoogleFonts.firaCode(fontSize: 11, color: _kMuted),
            ),
          ],
        ],
      );
    } else if (state is CreatePostPublishing) {
      return Column(
        children: [
          Text(
            'Publishing…',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kFg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finishing up…',
            style: GoogleFonts.firaCode(fontSize: 11, color: _kMuted),
          ),
        ],
      );
    } else if (state is CreatePostError) {
      final failedFile = state.draft.localMediaPaths
          .where((p) => !state.draft.uploadedUrls.containsKey(p))
          .map((p) => p.split('/').last)
          .firstOrNull;
      return Column(
        children: [
          Text(
            'Upload failed',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kDestructive,
            ),
          ),
          if (failedFile != null) ...[
            const SizedBox(height: 4),
            Text(
              '$failedFile could not be uploaded',
              style: GoogleFonts.firaCode(fontSize: 11, color: _kMuted),
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFileList(List<FileUploadProgress> files) {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < files.length; i++)
            _FileRow(file: files[i], isLast: i == files.length - 1),
        ],
      ),
    );
  }

  Widget _buildFileListAllDone() {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: _kGreen,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(CreatePostError state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        state.message,
        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: _kDestructive),
      ),
    );
  }

  Widget _buildRetryButton(CreatePostError state) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton(
        onPressed: () {
          ref.read(createPostProvider.notifier).submit(draft: state.draft);
        },
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: _kWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          'Retry',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.isLast});

  final FileUploadProgress file;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: file.phase == FileUploadPhase.queued ? 0.45 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              children: [
                Row(
                  children: [
                    _PhaseIcon(phase: file.phase),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        file.filename,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: file.phase == FileUploadPhase.queued
                              ? _kMuted
                              : _kFg,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PhaseLabel(file: file),
                  ],
                ),
                if (file.phase == FileUploadPhase.uploading) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: LinearProgressIndicator(
                      value: file.progress,
                      minHeight: 3,
                      backgroundColor: _kBorder,
                      valueColor: const AlwaysStoppedAnimation(_kPrimary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, color: _kBorder),
      ],
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon({required this.phase});
  final FileUploadPhase phase;

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      FileUploadPhase.done => Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: _kGreenBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 10,
          color: _kGreen,
        ),
      ),
      FileUploadPhase.uploading => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation(_kPrimary),
        ),
      ),
      FileUploadPhase.queued => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _kMuted, width: 1.5),
        ),
      ),
    };
  }
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({required this.file});
  final FileUploadProgress file;

  @override
  Widget build(BuildContext context) {
    return switch (file.phase) {
      FileUploadPhase.done => Text(
        'Done',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kGreen,
        ),
      ),
      FileUploadPhase.uploading => Text(
        '${(file.progress * 100).toInt()}%',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kPrimary,
        ),
      ),
      FileUploadPhase.queued => Text(
        'Queued',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          color: _kMuted,
        ),
      ),
    };
  }
}
