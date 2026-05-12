import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class CourseStep extends ConsumerWidget {
  const CourseStep({
    super.key,
    required this.universityId,
    required this.selectedDepartmentId,
    required this.selectedYear,
    required this.selectedCourseId,
    required this.onDepartmentChanged,
    required this.onYearChanged,
    required this.onCourseChanged,
  });

  final String universityId;
  final String? selectedDepartmentId;
  final int? selectedYear;
  final String? selectedCourseId;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<String?> onCourseChanged;

  static const _years = [1, 2, 3, 4, 5, 6];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final deptsAsync = ref.watch(
      departmentsForUniversityProvider(universityId),
    );

    final coursesAsync = (selectedDepartmentId != null && selectedYear != null)
        ? ref.watch(coursesProvider(selectedDepartmentId!, selectedYear!))
        : const AsyncData(<({String id, String name})>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which course is this for?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 24),

        // DEPARTMENT
        _FieldLabel('DEPARTMENT'),
        const SizedBox(height: 6),
        deptsAsync.when(
          loading: () => _DropdownField<String>(
            value: null,
            hint: 'Loading…',
            items: const [],
            onChanged: null,
          ),
          error: (_, _) => _DropdownField<String>(
            value: null,
            hint: 'Failed to load',
            items: const [],
            onChanged: null,
          ),
          data: (depts) => _DropdownField<String>(
            value: selectedDepartmentId,
            hint: 'Select department',
            items: depts
                .map(
                  (d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(
                      d.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              onDepartmentChanged(v);
              onYearChanged(null);
              onCourseChanged(null);
            },
          ),
        ),
        const SizedBox(height: 16),

        // YEAR
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            onYearChanged(v);
            onCourseChanged(null);
          },
        ),
        const SizedBox(height: 16),

        // COURSE
        _FieldLabel('COURSE'),
        const SizedBox(height: 6),
        _buildCourseDropdown(context, coursesAsync),
      ],
    );
  }

  Widget _buildCourseDropdown(
    BuildContext context,
    AsyncValue<List<({String id, String name})>> coursesAsync,
  ) {
    final cs = Theme.of(context).colorScheme;
    if (selectedDepartmentId == null) {
      return _DropdownField<String>(
        value: null,
        hint: 'Select a department first',
        items: const [],
        onChanged: null,
      );
    }
    if (selectedYear == null) {
      return _DropdownField<String>(
        value: null,
        hint: 'Select a year first',
        items: const [],
        onChanged: null,
      );
    }
    return coursesAsync.when(
      loading: () => _DropdownField<String>(
        value: null,
        hint: 'Loading…',
        items: const [],
        onChanged: null,
      ),
      error: (_, _) => _DropdownField<String>(
        value: null,
        hint: 'Failed to load',
        items: const [],
        onChanged: null,
      ),
      data: (courses) => _DropdownField<String>(
        value: selectedCourseId,
        hint: courses.isEmpty ? 'No courses found' : 'Select course',
        items: courses
            .map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Text(
                  c.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: courses.isEmpty ? null : onCourseChanged,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Text(
      text,
      style: AppTypography.mono(
        base: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: ac.mutedForeground,
          letterSpacing: 0.55,
        ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ac.mutedForeground,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ac.mutedForeground,
            size: 18,
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
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
