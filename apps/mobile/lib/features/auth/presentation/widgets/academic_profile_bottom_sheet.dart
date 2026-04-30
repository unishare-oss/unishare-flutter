import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_repository_provider.dart';
import '../providers/auth_state_provider.dart';
import '../providers/departments_provider.dart';

class AcademicProfileBottomSheet extends ConsumerStatefulWidget {
  const AcademicProfileBottomSheet({super.key});

  @override
  ConsumerState<AcademicProfileBottomSheet> createState() =>
      _AcademicProfileBottomSheetState();
}

class _AcademicProfileBottomSheetState
    extends ConsumerState<AcademicProfileBottomSheet> {
  String? _selectedDepartmentId;
  int? _selectedEnrollmentYear;
  bool _isSaving = false;

  static final List<int> _years = List.generate(
    2030 - 2015 + 1,
    (i) => 2015 + i,
  );

  Future<void> _save() async {
    final authAsync = ref.read(authStateProvider);
    final user = authAsync.hasValue ? authAsync.value : null;
    if (user == null || _selectedDepartmentId == null) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateAcademicProfile(
            uid: user.id,
            departmentId: _selectedDepartmentId!,
            enrollmentYear: _selectedEnrollmentYear,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departmentsAsync = ref.watch(departmentsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Complete your academic profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Help us personalise your feed by adding your department.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          departmentsAsync.when(
            data: (departments) => DropdownButtonFormField<String>(
              initialValue: _selectedDepartmentId,
              hint: const Text('Select department *'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: departments
                  .map(
                    (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedDepartmentId = val),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const Text('Failed to load departments'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedEnrollmentYear,
            hint: const Text('Enrollment year (optional)'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: _years
                .map(
                  (y) => DropdownMenuItem(value: y, child: Text(y.toString())),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedEnrollmentYear = val),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_selectedDepartmentId != null && !_isSaving)
                ? _save
                : null,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Do it later',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAcademicProfileBottomSheet(BuildContext context) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const AcademicProfileBottomSheet(),
  );
}
