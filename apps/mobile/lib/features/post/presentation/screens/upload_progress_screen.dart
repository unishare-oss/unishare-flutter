import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/presentation/providers/create_post_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

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
      if (next is CreatePostPublished || next is CreatePostQueued) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (next is CreatePostQueued) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved offline — will publish when you reconnect.'),
              ),
            );
          }
          ref.read(createPostProvider.notifier).reset();
          GoRouter.of(context).go('/feed');
        });
      }
    });

    final state = ref.watch(createPostProvider);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(context, state),
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  AppBar _buildAppBar(BuildContext context, CreatePostState state) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final dividerColor = Theme.of(context).dividerColor;
    final isPublishing = state is CreatePostPublishing;
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Text(
        'Uploading Post',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: isPublishing
                ? null
                : () async {
                    final router = GoRouter.of(context);
                    await ref.read(createPostProvider.notifier).cancel();
                    if (!mounted) return;
                    router.go('/feed');
                  },
            style: TextButton.styleFrom(
              foregroundColor: cs.error,
              disabledForegroundColor: ac.mutedForeground,
              side: BorderSide(
                color: isPublishing
                    ? dividerColor
                    : cs.error.withValues(alpha: 0.4),
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
        child: Container(height: 1, color: dividerColor),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CreatePostState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          _buildRing(context, state),
          const SizedBox(height: 12),
          _buildSubtitles(context, state),
          const SizedBox(height: 28),
          if (state is CreatePostUploading) ...[
            _buildFileList(context, state.files),
            const SizedBox(height: 20),
            _buildGoToFeedButton(context),
          ],
          if (state is CreatePostPublishing)
            _buildFileList(context, state.files),
          if (state is CreatePostError) ...[
            _buildErrorBanner(context, state),
            const SizedBox(height: 16),
            _buildRetryButton(context, state),
          ],
        ],
      ),
    );
  }

  Widget _buildRing(BuildContext context, CreatePostState state) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final Color ringColor;
    final Color ringBg;
    final Widget center;

    if (state is CreatePostUploading) {
      ringColor = ac.amber;
      ringBg = dividerColor;
      final pct = (state.overallProgress * 100).toInt();
      center = Text(
        '$pct%',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ac.amber,
        ),
      );
    } else if (state is CreatePostPublishing) {
      ringColor = ac.success;
      ringBg = ac.success.withValues(alpha: 0.15);
      center = Icon(Icons.check_rounded, size: 32, color: ac.success);
    } else if (state is CreatePostError) {
      ringColor = cs.error;
      ringBg = cs.error.withValues(alpha: 0.1);
      center = Icon(Icons.priority_high_rounded, size: 32, color: cs.error);
    } else {
      // CreatePostPublished — same green as Publishing while listener navigates away.
      ringColor = ac.success;
      ringBg = ac.success.withValues(alpha: 0.15);
      center = Icon(Icons.check_rounded, size: 32, color: ac.success);
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

  Widget _buildSubtitles(BuildContext context, CreatePostState state) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
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
              color: cs.onSurface,
            ),
          ),
          if (uploading != null) ...[
            const SizedBox(height: 4),
            Text(
              'Uploading $uploading…',
              style: GoogleFonts.firaCode(
                fontSize: 11,
                color: ac.mutedForeground,
              ),
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
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finishing up…',
            style: GoogleFonts.firaCode(
              fontSize: 11,
              color: ac.mutedForeground,
            ),
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
              color: cs.error,
            ),
          ),
          if (failedFile != null) ...[
            const SizedBox(height: 4),
            Text(
              '$failedFile could not be uploaded',
              style: GoogleFonts.firaCode(
                fontSize: 11,
                color: ac.mutedForeground,
              ),
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFileList(BuildContext context, List<FileUploadProgress> files) {
    final cs = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: dividerColor),
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

  Widget _buildGoToFeedButton(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return TextButton(
      onPressed: () => context.go('/feed'),
      child: Text(
        'Go to feed — upload continues in background',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: ac.mutedForeground,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, CreatePostError state) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.06),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        state.message,
        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: cs.error),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context, CreatePostError state) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton(
        onPressed: () {
          ref.read(createPostProvider.notifier).submit(draft: state.draft);
        },
        style: FilledButton.styleFrom(
          backgroundColor: ac.amber,
          foregroundColor: Colors.white,
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
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final dividerColor = Theme.of(context).dividerColor;
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
                              ? ac.mutedForeground
                              : cs.onSurface,
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
                      backgroundColor: dividerColor,
                      valueColor: AlwaysStoppedAnimation(ac.amber),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: dividerColor),
      ],
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon({required this.phase});
  final FileUploadPhase phase;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return switch (phase) {
      FileUploadPhase.done => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: ac.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 10, color: ac.success),
      ),
      FileUploadPhase.uploading => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(ac.amber),
        ),
      ),
      FileUploadPhase.queued => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ac.mutedForeground, width: 1.5),
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
    final ac = Theme.of(context).extension<AppColors>()!;
    return switch (file.phase) {
      FileUploadPhase.done => Text(
        'Done',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ac.success,
        ),
      ),
      FileUploadPhase.uploading => Text(
        '${(file.progress * 100).toInt()}%',
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ac.amber,
        ),
      ),
      FileUploadPhase.queued => Text(
        'Queued',
        style: GoogleFonts.firaCode(fontSize: 11, color: ac.mutedForeground),
      ),
    };
  }
}
