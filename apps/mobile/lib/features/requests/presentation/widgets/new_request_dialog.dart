import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unishare_mobile/features/post/presentation/providers/course_reference_provider.dart';
import 'package:unishare_mobile/features/requests/presentation/providers/request_repository_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class NewRequestDialog extends ConsumerStatefulWidget {
  const NewRequestDialog({super.key});

  @override
  ConsumerState<NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends ConsumerState<NewRequestDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedDepartmentId;
  String? _selectedDepartmentName;
  String? _selectedYear;
  String? _selectedCourseId;
  String? _selectedCourseName;
  bool _isSubmitting = false;

  static const _years = ['1', '2', '3', '4'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _selectedDepartmentId != null &&
      _selectedYear != null &&
      _selectedCourseId != null &&
      !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(createRequestUseCaseProvider);
      await useCase(
        departmentId: _selectedDepartmentId!,
        departmentName: _selectedDepartmentName ?? '',
        year: _selectedYear!,
        courseId: _selectedCourseId!,
        courseName: _selectedCourseName ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request posted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post request: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final deptsAsync = ref.watch(departmentsForUniversityProvider(''));
    final coursesAsync =
        (_selectedDepartmentId != null && _selectedYear != null)
        ? ref.watch(
            coursesProvider(
              _selectedDepartmentId!,
              int.tryParse(_selectedYear!) ?? 1,
            ),
          )
        : const AsyncData(<({String id, String name})>[]);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'New Resource Request',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title field
              _FieldLabel('WHAT DO YOU NEED?', ac),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                maxLength: 120,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. Data Structures midterm notes',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: ac.mutedForeground,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: ac.amber, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Department + Year row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('DEPARTMENT', ac),
                        const SizedBox(height: 6),
                        deptsAsync.when(
                          loading: () => _DropdownField<String>(
                            value: null,
                            hint: 'Loading...',
                            items: const [],
                            onChanged: null,
                            ac: ac,
                            cs: cs,
                            dividerColor: theme.dividerColor,
                          ),
                          error: (_, _) => _DropdownField<String>(
                            value: null,
                            hint: 'Failed to load',
                            items: const [],
                            onChanged: null,
                            ac: ac,
                            cs: cs,
                            dividerColor: theme.dividerColor,
                          ),
                          data: (depts) => _DropdownField<String>(
                            value: _selectedDepartmentId,
                            hint: 'Select dept',
                            items: depts
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(
                                      d.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedDepartmentId = v;
                                _selectedDepartmentName = deptsAsync
                                    .asData
                                    ?.value
                                    .firstWhere(
                                      (d) => d.id == v,
                                      orElse: () => (id: v ?? '', name: ''),
                                    )
                                    .name;
                                _selectedYear = null;
                                _selectedCourseId = null;
                                _selectedCourseName = null;
                              });
                            },
                            ac: ac,
                            cs: cs,
                            dividerColor: theme.dividerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('YEAR', ac),
                        const SizedBox(height: 6),
                        _DropdownField<String>(
                          value: _selectedYear,
                          hint: 'Select year',
                          items: _years
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    'Year $y',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedYear = v;
                              _selectedCourseId = null;
                              _selectedCourseName = null;
                            });
                          },
                          ac: ac,
                          cs: cs,
                          dividerColor: theme.dividerColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Course dropdown
              _FieldLabel('COURSE', ac),
              const SizedBox(height: 6),
              coursesAsync.when(
                loading: () => _DropdownField<String>(
                  value: null,
                  hint: 'Loading...',
                  items: const [],
                  onChanged: null,
                  ac: ac,
                  cs: cs,
                  dividerColor: theme.dividerColor,
                ),
                error: (_, _) => _DropdownField<String>(
                  value: null,
                  hint: 'Failed to load',
                  items: const [],
                  onChanged: null,
                  ac: ac,
                  cs: cs,
                  dividerColor: theme.dividerColor,
                ),
                data: (courses) {
                  if (_selectedDepartmentId == null) {
                    return _DropdownField<String>(
                      value: null,
                      hint: 'Select a department first',
                      items: const [],
                      onChanged: null,
                      ac: ac,
                      cs: cs,
                      dividerColor: theme.dividerColor,
                    );
                  }
                  if (_selectedYear == null) {
                    return _DropdownField<String>(
                      value: null,
                      hint: 'Select a year first',
                      items: const [],
                      onChanged: null,
                      ac: ac,
                      cs: cs,
                      dividerColor: theme.dividerColor,
                    );
                  }
                  return _DropdownField<String>(
                    value: _selectedCourseId,
                    hint: courses.isEmpty
                        ? 'No courses found'
                        : 'Select course',
                    items: courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: courses.isEmpty
                        ? null
                        : (v) {
                            setState(() {
                              _selectedCourseId = v;
                              _selectedCourseName = courses
                                  .firstWhere(
                                    (c) => c.id == v,
                                    orElse: () => (id: v ?? '', name: ''),
                                  )
                                  .name;
                            });
                          },
                    ac: ac,
                    cs: cs,
                    dividerColor: theme.dividerColor,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Details optional
              _FieldLabel('DETAILS (OPTIONAL)', ac),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Add more context — which chapter, what semester, etc.',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: ac.mutedForeground,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: ac.amber, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.amber,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: ac.amber.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Post Request'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, this.ac);
  final String text;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
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
