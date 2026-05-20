import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Color constants — hardcoded so this widget is theme-agnostic for the mock
// phase. Replace with Theme.of(context).extension<AppColors>() when wiring
// real data.
// ---------------------------------------------------------------------------

const _kOrange = Color(0xFFD97706);
const _kNoteBlue = Color(0xFF0369A1);
const _kNoteBlueBg = Color(0xFFE0F0F8);
const _kAssignmentBg = Color(0xFFFEF3C7);
const _kMuted = Color(0xFFF7F3EE);
const _kTextMuted = Color(0xFF8A837E);
const _kTextSecondary = Color(0xFF6B6560);
const _kForeground = Color(0xFF1C1917);

// ---------------------------------------------------------------------------
// Mock data model — used only until Firestore wiring is complete
// ---------------------------------------------------------------------------

enum MockPostType { note, assignment }

class MockPost {
  const MockPost({
    required this.type,
    required this.courseCode,
    required this.title,
    this.topicTags = const [],
    required this.authorInitials,
    required this.authorName,
    required this.authorYear,
    required this.commentCount,
    required this.timeAgo,
  });

  final MockPostType type;
  final String courseCode;
  final String title;
  final List<String> topicTags;
  final String authorInitials;
  final String authorName;
  final int authorYear;
  final int commentCount;
  final String timeAgo;
}

// ---------------------------------------------------------------------------
// PostCardWidget
// ---------------------------------------------------------------------------

class PostCardWidget extends StatelessWidget {
  const PostCardWidget({super.key, required this.post});

  final MockPost post;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopRow(),
            const SizedBox(height: 6),
            _buildTitle(),
            if (post.topicTags.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildTagsWrap(),
            ],
            const SizedBox(height: 8),
            _buildAuthorRow(),
            const SizedBox(height: 6),
            _buildMetaRow(),
          ],
        ),
      ),
    );
  }

  // Row 1: type badge + course code chip + bookmark icon
  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TypeBadge(type: post.type),
        const SizedBox(width: 6),
        _CourseCodeChip(code: post.courseCode),
        const Spacer(),
        Icon(Icons.bookmark_border_outlined, size: 18, color: _kTextMuted),
      ],
    );
  }

  // Row 2: title
  Widget _buildTitle() {
    return Text(
      post.title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _kForeground,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Row 3: topic tag chips (Wrap)
  Widget _buildTagsWrap() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: post.topicTags.map((tag) => _TagChip(label: tag)).toList(),
    );
  }

  // Row 4: author avatar + name + year
  Widget _buildAuthorRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: _kOrange.withValues(alpha: 0.15),
          foregroundColor: _kOrange,
          child: Text(
            post.authorInitials,
            style: GoogleFonts.firaCode(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: _kOrange,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          post.authorName,
          style: const TextStyle(fontSize: 12, color: _kTextSecondary),
        ),
        Text(
          ' · Year ${post.authorYear} ·',
          style: const TextStyle(fontSize: 12, color: _kTextMuted),
        ),
      ],
    );
  }

  // Row 5: comment count + time ago
  Widget _buildMetaRow() {
    final commentLabel = post.commentCount == 1
        ? '1 comment'
        : '${post.commentCount} comments';
    return Row(
      children: [
        Icon(Icons.chat_bubble_outline, size: 12, color: _kTextMuted),
        const SizedBox(width: 3),
        Text(
          commentLabel,
          style: const TextStyle(fontSize: 11, color: _kTextMuted),
        ),
        const Text(' · ', style: TextStyle(fontSize: 11, color: _kTextMuted)),
        Text(
          post.timeAgo,
          style: const TextStyle(fontSize: 11, color: _kTextMuted),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final MockPostType type;

  @override
  Widget build(BuildContext context) {
    final isNote = type == MockPostType.note;
    final bg = isNote ? _kNoteBlueBg : _kAssignmentBg;
    final fg = isNote ? _kNoteBlue : _kOrange;
    final label = isNote ? 'NOTE' : 'ASSIGNMENT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.firaCode(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
          letterSpacing: 0.55,
        ),
      ),
    );
  }
}

class _CourseCodeChip extends StatelessWidget {
  const _CourseCodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Text(
      code,
      style: GoogleFonts.firaCode(
        fontSize: 11,
        color: _kTextMuted,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.firaCode(
          fontSize: 10,
          color: _kTextSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
