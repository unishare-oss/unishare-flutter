import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _yearController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  int? get _enrollmentYear {
    final v = int.tryParse(_yearController.text.trim());
    if (v == null) return null;
    if (v < 2000 || v > 2030) return null;
    return v;
  }

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
            enrollmentYear: _enrollmentYear,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Complete your profile',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Tell us a bit about your academic background. You can update this later in your profile.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Department dropdown
          departmentsAsync.when(
            data: (departments) => DropdownButtonFormField<String>(
              initialValue: _selectedDepartmentId,
              isExpanded: true,
              hint: Text(
                'Select your department',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: departments
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(
                        d.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedDepartmentId = val),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const Text('Failed to load departments'),
          ),
          const SizedBox(height: 12),

          // Enrollment year text field
          TextFormField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: GoogleFonts.spaceGrotesk(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enrollment year (e.g. 2023)',
              hintStyle: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Do it later',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed:
                      (_selectedDepartmentId != null && !_isSaving)
                          ? _save
                          : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showAcademicProfileBottomSheet(BuildContext context) async {
  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: const AcademicProfileBottomSheet(),
      ),
    ),
  );
}
