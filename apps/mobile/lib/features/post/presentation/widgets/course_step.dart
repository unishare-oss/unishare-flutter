import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// Step 2: year + course dropdowns.
///
/// Courses are loaded from a simple in-memory list keyed by year for v1.
/// When Firestore reference data is seeded, this can be replaced with a
/// StreamProvider that queries the `courses` collection filtered by year.
class CourseStep extends StatelessWidget {
  const CourseStep({
    super.key,
    required this.selectedYear,
    required this.selectedCourseId,
    required this.onYearChanged,
    required this.onCourseChanged,
  });

  final int? selectedYear;
  final String? selectedCourseId;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<String?> onCourseChanged;

  static const _years = [1, 2, 3, 4];

  /// Placeholder course list until Firestore reference data is seeded.
  static const _courses = <int, List<_Course>>{
    1: [
      _Course('csc101', 'CSC101 Introduction to Computing'),
      _Course('mat101', 'MAT101 Calculus I'),
      _Course('eng101', 'ENG101 Technical Writing'),
    ],
    2: [
      _Course('csc201', 'CSC201 Data Structures'),
      _Course('csc202', 'CSC202 Algorithms'),
      _Course('mat201', 'MAT201 Linear Algebra'),
    ],
    3: [
      _Course('csc301', 'CSC301 Operating Systems'),
      _Course('csc302', 'CSC302 Database Systems'),
      _Course('csc303', 'CSC303 Software Engineering'),
    ],
    4: [
      _Course('csc401', 'CSC401 Machine Learning'),
      _Course('csc402', 'CSC402 Distributed Systems'),
      _Course('csc403', 'CSC403 Final Year Project'),
    ],
  };

  List<_Course> get _currentCourses =>
      selectedYear != null ? (_courses[selectedYear] ?? []) : [];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which course is this for?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        _FieldLabel('YEAR'),
        const SizedBox(height: 6),
        _DropdownField<int>(
          value: selectedYear,
          hint: 'Select year',
          items: _years
              .map(
                (y) => DropdownMenuItem(
                  value: y,
                  child: Text(
                    'Year $y',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            onYearChanged(v);
            // Reset course when year changes.
            onCourseChanged(null);
          },
        ),
        const SizedBox(height: 16),
        _FieldLabel('COURSE'),
        const SizedBox(height: 6),
        _DropdownField<String>(
          value: selectedCourseId,
          hint: selectedYear == null ? 'Select a year first' : 'Select course',
          items: _currentCourses
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    c.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: selectedYear != null ? onCourseChanged : null,
        ),
      ],
    );
  }
}

class _Course {
  const _Course(this.id, this.name);
  final String id;
  final String name;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Text(
      text,
      style: GoogleFonts.firaCode(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ac.mutedForeground,
        letterSpacing: 0.55,
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final dividerColor = Theme.of(context).dividerColor;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: ac.mutedForeground,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ac.mutedForeground,
            size: 18,
          ),
          style: GoogleFonts.spaceGrotesk(fontSize: 14, color: cs.onSurface),
          items: items,
          onChanged: onChanged,
          focusColor: Colors.transparent,
          dropdownColor: cs.surface,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
