import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/providers/profile_form_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/appearance_section.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/connected_accounts_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/danger_zone_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_form_card.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// ProfileScreen still holds [TextEditingController]s (they have their own
/// lifecycle and don't fit a Riverpod store cleanly), but all other mutable
/// form state lives in [profileFormProvider]. The screen is essentially a
/// view that wires controllers + provider together.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _controllersSeeded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _seedControllers(AppUser user) {
    if (_controllersSeeded) return;
    _controllersSeeded = true;
    _nameCtrl.text = user.name;
    _bioCtrl.text = user.bio ?? '';
  }

  /// Returns an error message if invalid, null if OK.
  String? _validate(ProfileFormState form) {
    if (_nameCtrl.text.trim().isEmpty) {
      return 'Display name is required';
    }
    final year = form.enrollmentYear;
    if (year != null) {
      final nextYear = DateTime.now().year + 1;
      if (year < 1900 || year > nextYear) {
        return 'Enrollment year must be between 1900 and $nextYear';
      }
    }
    return null;
  }

  Future<void> _save(AppUser user) async {
    final form = ref.read(profileFormProvider);
    if (form.saving) return;
    final validationError = _validate(form);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    ref.read(profileFormProvider.notifier).setSaving(true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            uid: user.id,
            name: _nameCtrl.text.trim(),
            bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
            universityId: form.universityId,
            departmentId: form.departmentId,
            enrollmentYear: form.enrollmentYear,
          );
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (e, st) {
      debugPrint('ProfileScreen save error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
      }
    } finally {
      if (mounted) {
        ref.read(profileFormProvider.notifier).setSaving(false);
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(signOutUseCaseProvider).call();
    ref.read(guestModeProvider.notifier).exit();
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final form = ref.watch(profileFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: Icon(Icons.logout, size: 16, color: ac.textMuted),
            label: Text(
              'Sign out',
              style: theme.textTheme.bodyMedium?.copyWith(color: ac.textMuted),
            ),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          debugPrint('ProfileScreen userAsync error: $e\n$st');
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "We couldn't load your profile right now. Please try again.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          _seedControllers(user);
          // Initialize form state after the build pass so we don't mutate
          // providers during a widget build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(profileFormProvider.notifier).initFromUser(user);
          });

          final notifier = ref.read(profileFormProvider.notifier);
          final sections = <Widget>[
            ProfileCard(user: user),
            const SizedBox(height: 16),
            ProfileFormCard(
              user: user,
              nameCtrl: _nameCtrl,
              bioCtrl: _bioCtrl,
              selectedUniversityId: form.universityId,
              selectedDepartmentId: form.departmentId,
              enrollmentYear: form.enrollmentYear,
              saving: form.saving,
              onUniversityChanged: notifier.setUniversity,
              onDepartmentChanged: notifier.setDepartment,
              onYearChanged: notifier.setEnrollmentYear,
              onSave: () => _save(user),
            ),
            const SizedBox(height: 16),
            const ConnectedAccountsCard(),
            const SizedBox(height: 16),
            const AppearanceSection(),
            const SizedBox(height: 16),
            const DangerZoneCard(),
            const SizedBox(height: 32),
          ];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sections.length,
            itemBuilder: (_, i) => sections[i],
          );
        },
      ),
    );
  }
}
