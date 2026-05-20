import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class RequestFilterBar extends ConsumerWidget {
  const RequestFilterBar({
    super.key,
    required this.selectedStatus,
    required this.selectedDepartmentId,
    required this.selectedYear,
    required this.selectedCourseId,
    required this.onStatusChanged,
    required this.onDepartmentChanged,
    required this.onYearChanged,
    required this.onCourseChanged,
  });

  final RequestStatus? selectedStatus;
  final String? selectedDepartmentId;
  final String? selectedYear;
  final String? selectedCourseId;
  final ValueChanged<RequestStatus?> onStatusChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<String?> onCourseChanged;

  static const _years = ['1', '2', '3', '4'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor;

    final universityId =
        ref.watch(currentUserProvider).value?.universityId ?? '';
    final deptsAsync = ref.watch(
      departmentsForUniversityProvider(universityId),
    );
    final coursesAsync = (selectedDepartmentId != null && selectedYear != null)
        ? ref.watch(
            coursesProvider(
              selectedDepartmentId!,
              int.tryParse(selectedYear!) ?? 1,
            ),
          )
        : const AsyncData(<({String id, String name})>[]);

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterDropdown<RequestStatus>(
              value: selectedStatus,
              hint: 'Status',
              items: [
                DropdownMenuItem(
                  value: null,
                  child: _dropdownText('All', theme, cs),
                ),
                DropdownMenuItem(
                  value: RequestStatus.open,
                  child: _dropdownText('Open', theme, cs),
                ),
                DropdownMenuItem(
                  value: RequestStatus.fulfilled,
                  child: _dropdownText('Fulfilled', theme, cs),
                ),
              ],
              onChanged: onStatusChanged,
              ac: ac,
              cs: cs,
              theme: theme,
              dividerColor: dividerColor,
            ),
            const SizedBox(width: 8),
            deptsAsync.when(
              loading: () => _FilterDropdown<String>(
                value: null,
                hint: 'Dept',
                items: const [],
                onChanged: null,
                ac: ac,
                cs: cs,
                theme: theme,
                dividerColor: dividerColor,
              ),
              error: (_, _) => _FilterDropdown<String>(
                value: null,
                hint: 'Dept',
                items: const [],
                onChanged: null,
                ac: ac,
                cs: cs,
                theme: theme,
                dividerColor: dividerColor,
              ),
              data: (depts) => _FilterDropdown<String>(
                value: selectedDepartmentId,
                hint: 'Dept',
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: _dropdownText('All Depts', theme, cs),
                  ),
                  ...depts.map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: _dropdownText(d.name, theme, cs),
                    ),
                  ),
                ],
                onChanged: (v) {
                  onDepartmentChanged(v);
                  onYearChanged(null);
                  onCourseChanged(null);
                },
                ac: ac,
                cs: cs,
                theme: theme,
                dividerColor: dividerColor,
              ),
            ),
            const SizedBox(width: 8),
            _FilterDropdown<String>(
              value: selectedYear,
              hint: 'Year',
              items: [
                DropdownMenuItem(
                  value: null,
                  child: _dropdownText('All Years', theme, cs),
                ),
                ..._years.map(
                  (y) => DropdownMenuItem(
                    value: y,
                    child: _dropdownText('Year $y', theme, cs),
                  ),
                ),
              ],
              onChanged: (v) {
                onYearChanged(v);
                onCourseChanged(null);
              },
              ac: ac,
              cs: cs,
              theme: theme,
              dividerColor: dividerColor,
            ),
            const SizedBox(width: 8),
            coursesAsync.when(
              loading: () => _FilterDropdown<String>(
                value: null,
                hint: 'Course',
                items: const [],
                onChanged: null,
                ac: ac,
                cs: cs,
                theme: theme,
                dividerColor: dividerColor,
              ),
              error: (_, _) => _FilterDropdown<String>(
                value: null,
                hint: 'Course',
                items: const [],
                onChanged: null,
                ac: ac,
                cs: cs,
                theme: theme,
                dividerColor: dividerColor,
              ),
              data: (courses) => _FilterDropdown<String>(
                value: selectedCourseId,
                hint: 'Course',
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: _dropdownText('All Courses', theme, cs),
                  ),
                  ...courses.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: _dropdownText(c.name, theme, cs),
                    ),
                  ),
                ],
                onChanged: selectedDepartmentId == null || selectedYear == null
                    ? null
                    : onCourseChanged,
                ac: ac,
                cs: cs,
                theme: theme,
                dividerColor: dividerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownText(String text, ThemeData theme, ColorScheme cs) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.ac,
    required this.cs,
    required this.theme,
    required this.dividerColor,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final AppColors ac;
  final ColorScheme cs;
  final ThemeData theme;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      constraints: const BoxConstraints(minWidth: 80, maxWidth: 150),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ac.mutedForeground,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ac.mutedForeground,
            size: 16,
          ),
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
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
