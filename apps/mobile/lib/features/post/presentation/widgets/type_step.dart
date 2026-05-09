import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class TypeStep extends StatelessWidget {
  const TypeStep({super.key, required this.selected, required this.onSelect});

  final PostType? selected;
  final ValueChanged<PostType> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are you sharing?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
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
          label: 'Exercise',
          description: 'Practice worksheets and problem sets',
          icon: Icons.assignment_outlined,
          type: PostType.exercise,
          selected: selected == PostType.exercise,
          onTap: () => onSelect(PostType.exercise),
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
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).dividerColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? ac.amberSubtle : cs.surface,
          border: Border.all(
            color: selected ? ac.amber : dividerColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? ac.amber.withValues(alpha: 0.2) : scaffoldBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 21,
                color: selected ? ac.amber : ac.mutedForeground,
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
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ac.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: ac.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 13, color: Theme.of(context).colorScheme.onPrimary),
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
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).dividerColor;
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: dividerColor, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scaffoldBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.school_outlined,
                size: 21,
                color: ac.mutedForeground,
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
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Old exam papers and question banks',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ac.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: scaffoldBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Unavailable',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: ac.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
