import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/logging/app_logger.dart';
import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/providers/profile_form_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/appearance_section.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/bio_visibility_notice.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/connected_accounts_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/danger_zone_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_form_card.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

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

  /// UID the text controllers were last seeded from. When the signed-in user
  /// changes (sign-out → sign-in as someone else) we re-seed so stale text
  /// doesn't survive the account switch.
  String? _seededUid;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _seedControllers(AppUser user) {
    if (_seededUid == user.id) return;
    _seededUid = user.id;
    _nameCtrl.text = user.name;
    _bioCtrl.text = user.bio ?? '';
  }

  /// Parses [form.enrollmentYearText]. Returns:
  /// - `(null, null)` when the field is empty (intentional clear),
  /// - `(year, null)` when the input is a valid year, or
  /// - `(null, errorMessage)` when the input is non-empty but invalid.
  ({int? year, String? error}) _parseYear(ProfileFormState form) {
    final raw = form.enrollmentYearText.trim();
    if (raw.isEmpty) return (year: null, error: null);
    final parsed = int.tryParse(raw);
    final currentYear = DateTime.now().year;
    if (parsed == null) {
      return (year: null, error: 'Enrollment year must be a number');
    }
    if (parsed < 1900 || parsed > currentYear) {
      return (
        year: null,
        error: 'Enrollment year must be between 1900 and $currentYear',
      );
    }
    return (year: parsed, error: null);
  }

  /// Returns an error message if invalid, null if OK.
  String? _validate(ProfileFormState form) {
    if (_nameCtrl.text.trim().isEmpty) {
      return 'Display name is required';
    }
    final parsed = _parseYear(form);
    if (parsed.error != null) return parsed.error;
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
            enrollmentYear: _parseYear(form).year,
          );
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (e, st) {
      AppLogger.error('ProfileScreen save error', error: e, stackTrace: st);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          "You'll need to sign in again to access your account.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(signOutUseCaseProvider).call();
      ref.read(guestModeProvider.notifier).exit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign out failed. Please try again.')),
        );
      }
    }
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
          AppLogger.error(
            'ProfileScreen userAsync error',
            error: e,
            stackTrace: st,
          );
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
          if (user == null) {
            // Guest / unauthenticated landing on /more/profile. Don't
            // strand them on a blank screen — surface a sign-in CTA.
            return const _SignInPrompt();
          }
          _seedControllers(user);
          // Initialize form state after the build pass so we don't mutate
          // providers during a widget build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(profileFormProvider.notifier).initFromUser(user);
          });

          final notifier = ref.read(profileFormProvider.notifier);
          final sections = <Widget>[
            BioVisibilityNotice(user: user),
            ProfileCard(user: user),
            const SizedBox(height: 16),
            ProfileFormCard(
              user: user,
              nameCtrl: _nameCtrl,
              bioCtrl: _bioCtrl,
              selectedUniversityId: form.universityId,
              selectedDepartmentId: form.departmentId,
              enrollmentYearText: form.enrollmentYearText,
              saving: form.saving,
              onUniversityChanged: notifier.setUniversity,
              onDepartmentChanged: notifier.setDepartment,
              onYearChanged: notifier.setEnrollmentYearText,
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
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MainNavBar.bottomInset,
            ),
            itemCount: sections.length,
            itemBuilder: (_, i) => sections[i],
          );
        },
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 48, color: ac.textMuted),
            const SizedBox(height: 12),
            Text(
              'Sign in to view your profile',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You need an account to edit your profile, manage posts, and track activity.',
              style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/welcome'),
              style: FilledButton.styleFrom(
                backgroundColor: ac.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
