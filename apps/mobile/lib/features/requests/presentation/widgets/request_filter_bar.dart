import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final dividerColor = Theme.of(context).dividerColor;

    final deptsAsync = ref.watch(departmentsForUniversityProvider(''));
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
            // Status filter
            _FilterDropdown<RequestStatus>(
              value: selectedStatus,
              hint: 'Status',
              items: [
                DropdownMenuItem(
                  value: null,
                  child: _dropdownText('All', cs, ac),
                ),
                DropdownMenuItem(
                  value: RequestStatus.open,
                  child: _dropdownText('Open', cs, ac),
                ),
                DropdownMenuItem(
                  value: RequestStatus.fulfilled,
                  child: _dropdownText('Fulfilled', cs, ac),
                ),
              ],
              onChanged: onStatusChanged,
              ac: ac,
              cs: cs,
              dividerColor: dividerColor,
            ),
            const SizedBox(width: 8),
            // Department filter
            deptsAsync.when(
              loading: () => _FilterDropdown<String>(
                value: null,
                hint: 'Dept',
                items: const [],
                onChanged: null,
                ac: ac,
                cs: cs,
                dividerColor: dividerColor,
              ),
              error: (_, _) => _FilterDropdown<String>(
                value: null,
                hint: 'Dept',
                items: const [],
                onChanged: null,
                ac: ac,
                cs: cs,
                dividerColor: dividerColor,
              ),
              data: (depts) => _FilterDropdown<String>(
                value: selectedDepartmentId,
                hint: 'Dept',
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: _dropdownText('All Depts', cs, ac),
                  ),
                  ...depts.map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: _dropdownText(d.name, cs, ac),
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
                dividerColor: dividerColor,
              ),
            ),
            const SizedBox(width: 8),
            // Year filter
            _FilterDropdown<String>(
              value: selectedYear,
              hint: 'Year',
              items: [
                DropdownMenuItem(
                  value: null,
                  child: _dropdownText('All Years', cs, ac),
                ),
                ..._years.map(
                  (y) => DropdownMenuItem(
                    value: y,
                    child: _dropdownText('Year $y', cs, ac),
                  ),
                ),
              ],
              onChanged: (v) {
                onYearChanged(v);
                onCourseChanged(null);
              },
              ac: ac,
              cs: cs,
              dividerColor: dividerColor,
            ),
            const SizedBox(width: 8),
            // Course filter
            coursesAsync.when(
              loading: () => _FilterDropdown<String>(
                value: null,
                hint: 'Course',
                items: const [],
                onChanged: null,
                ac: ac,
                cs: cs,
                dividerColor: dividerColor,
              ),
              error: (_, _) => _FilterDropdown<String>(
                value: null,
                hint: 'Course',
                items: const [],
                onChanged: null,
                ac: ac,
                cs: cs,
                dividerColor: dividerColor,
              ),
              data: (courses) => _FilterDropdown<String>(
                value: selectedCourseId,
                hint: 'Course',
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: _dropdownText('All Courses', cs, ac),
                  ),
                  ...courses.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: _dropdownText(c.name, cs, ac),
                    ),
                  ),
                ],
                onChanged: selectedDepartmentId == null || selectedYear == null
                    ? null
                    : onCourseChanged,
                ac: ac,
                cs: cs,
                dividerColor: dividerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownText(String text, ColorScheme cs, AppColors ac) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(fontSize: 13, color: cs.onSurface),
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
    required this.dividerColor,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final AppColors ac;
  final ColorScheme cs;
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
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: ac.mutedForeground,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ac.mutedForeground,
            size: 16,
          ),
          style: GoogleFonts.spaceGrotesk(fontSize: 13, color: cs.onSurface),
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
