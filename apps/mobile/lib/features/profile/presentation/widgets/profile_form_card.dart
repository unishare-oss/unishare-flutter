import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/departments_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/universities_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_field_label.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class ProfileFormCard extends ConsumerWidget {
  const ProfileFormCard({
    super.key,
    required this.user,
    required this.nameCtrl,
    required this.bioCtrl,
    required this.selectedUniversityId,
    required this.selectedDepartmentId,
    required this.enrollmentYear,
    required this.saving,
    required this.onUniversityChanged,
    required this.onDepartmentChanged,
    required this.onYearChanged,
    required this.onSave,
  });

  final AppUser user;
  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final String? selectedUniversityId;
  final String? selectedDepartmentId;
  final int? enrollmentYear;
  final bool saving;
  final ValueChanged<String?> onUniversityChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<int?> onYearChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final unis = ref.watch(universitiesProvider).asData?.value ?? [];
    final depts = ref.watch(departmentsProvider).asData?.value ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFILE',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),
          const ProfileFieldLabel('DISPLAY NAME'),
          const SizedBox(height: 6),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const ProfileFieldLabel('BIO'),
          const SizedBox(height: 6),
          TextField(
            controller: bioCtrl,
            maxLength: 300,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          const ProfileFieldLabel('UNIVERSITY'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: selectedUniversityId,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: unis
                .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                .toList(),
            onChanged: onUniversityChanged,
          ),
          const SizedBox(height: 16),
          const ProfileFieldLabel('DEPARTMENT'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: selectedDepartmentId,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: depts
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
            onChanged: onDepartmentChanged,
          ),
          const SizedBox(height: 16),
          const ProfileFieldLabel('ENROLLMENT YEAR'),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: enrollmentYear?.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(),
            onChanged: (v) => onYearChanged(int.tryParse(v)),
          ),
          const SizedBox(height: 4),
          Text(
            'Used to calculate your year level',
            style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: ac.amber,
                foregroundColor: Colors.white,
              ),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
