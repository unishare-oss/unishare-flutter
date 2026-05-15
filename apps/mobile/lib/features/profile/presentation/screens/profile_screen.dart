import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/appearance_section.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/change_password_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/connected_accounts_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/danger_zone_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_card.dart';
import 'package:unishare_mobile/features/profile/presentation/widgets/profile_form_card.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _selectedUniversityId;
  String? _selectedDepartmentId;
  int? _enrollmentYear;
  bool _saving = false;
  bool _formInitialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _initForm(AppUser user) {
    if (_formInitialized) return;
    _formInitialized = true;
    _nameCtrl.text = user.name;
    _bioCtrl.text = user.bio ?? '';
    _selectedUniversityId = user.universityId;
    _selectedDepartmentId = user.departmentId;
    _enrollmentYear = user.enrollmentYear;
  }

  Future<void> _save(AppUser user) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            uid: user.id,
            name: _nameCtrl.text.trim(),
            bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
            universityId: _selectedUniversityId,
            departmentId: _selectedDepartmentId,
            enrollmentYear: _enrollmentYear,
          );
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
          _initForm(user);
          final sections = <Widget>[
            ProfileCard(user: user),
            const SizedBox(height: 16),
            ProfileFormCard(
              user: user,
              nameCtrl: _nameCtrl,
              bioCtrl: _bioCtrl,
              selectedUniversityId: _selectedUniversityId,
              selectedDepartmentId: _selectedDepartmentId,
              enrollmentYear: _enrollmentYear,
              saving: _saving,
              onUniversityChanged: (id) =>
                  setState(() => _selectedUniversityId = id),
              onDepartmentChanged: (id) =>
                  setState(() => _selectedDepartmentId = id),
              onYearChanged: (y) => setState(() => _enrollmentYear = y),
              onSave: () => _save(user),
            ),
            const SizedBox(height: 16),
            const ChangePasswordCard(),
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
