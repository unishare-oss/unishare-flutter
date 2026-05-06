import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/post_draft.dart';

const _kBg = Color(0xFFF7F3EE);
const _kWhite = Colors.white;
const _kPrimary = Color(0xFFD97706);
const _kPrimaryFill = Color(0xFFFEF3C7);
const _kBorder = Color(0xFFE2DAD0);
const _kFg = Color(0xFF1C1917);
const _kMuted = Color(0xFF8A837E);

class TypeStep extends StatelessWidget {
  const TypeStep({super.key, required this.selected, required this.onSelect});

  final PostType? selected;
  final ValueChanged<PostType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are you sharing?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kFg,
          ),
        ),
        const SizedBox(height: 24),
        _TypeCard(
          label: 'Lecture Note',
          description: 'Summaries, slides, or personal notes',
          icon: Icons.description_outlined,
          type: PostType.lectureNote,
          selected: selected == PostType.lectureNote,
          onTap: () => onSelect(PostType.lectureNote),
        ),
        const SizedBox(height: 12),
        _PastExamCard(),
        const SizedBox(height: 12),
        _TypeCard(
          label: 'Assignment',
          description: 'Practice worksheets and problem sets',
          icon: Icons.assignment_outlined,
          type: PostType.assignment,
          selected: selected == PostType.assignment,
          onTap: () => onSelect(PostType.assignment),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final PostType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? _kPrimaryFill : _kWhite,
          border: Border.all(color: selected ? _kPrimary : _kBorder, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? _kPrimary.withValues(alpha: 0.2) : _kBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 21,
                color: selected ? _kPrimary : _kMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _kFg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 21,
                height: 21,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 13, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _PastExamCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kWhite,
          border: Border.all(color: _kBorder, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 21,
                color: _kMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Past Exam',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _kFg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Old exam papers and question banks',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Unavailable',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _kMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
