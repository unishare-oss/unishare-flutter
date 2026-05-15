import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/departments_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/universities_provider.dart';
import 'package:unishare_mobile/features/post/presentation/providers/post_repository_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_posts_provider.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_theme_data.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';
import 'package:unishare_mobile/shared/theme/providers/font_size_provider.dart';
import 'package:unishare_mobile/shared/theme/providers/theme_provider.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

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
    final cs = Theme.of(context).colorScheme;
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
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          _initForm(user);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileCard(user: user),
              const SizedBox(height: 16),
              _ProfileFormCard(
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
              _ChangePasswordCard(),
              const SizedBox(height: 16),
              _ConnectedAccountsCard(),
              const SizedBox(height: 16),
              _AppearanceSection(),
              const SizedBox(height: 16),
              _DangerZoneCard(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    final depts = ref.watch(departmentsProvider).asData?.value ?? [];
    ref.watch(universitiesProvider);
    final deptName = depts
        .firstWhere(
          (d) => d.id == user.departmentId,
          orElse: () => (id: '', name: ''),
        )
        .name;
    final postsAsync = ref.watch(_userPostsCountProvider(user.id));
    final savedCount = ref.watch(savedPostsProvider).asData?.value.length ?? 0;

    final joinedYear = user.enrollmentYear ?? DateTime.now().year;
    final yearLevel = (DateTime.now().year - joinedYear) + 1;
    final cs = Theme.of(context).colorScheme;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(photoUrl: user.photoUrl, name: user.name),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTypography.mono(
                        base: theme.textTheme.bodySmall?.copyWith(
                          color: ac.textMuted,
                        ),
                      ),
                    ),
                    if ((user.bio ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(user.bio!, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Badge(user.role.toUpperCase()),
                        if (deptName.isNotEmpty) _Badge(deptName.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Joined $joinedYear',
                      style: AppTypography.mono(
                        base: theme.textTheme.labelSmall?.copyWith(
                          color: ac.textMuted,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Year $yearLevel Student',
                      style: AppTypography.mono(
                        base: theme.textTheme.labelSmall?.copyWith(
                          color: ac.amber,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stat(
                label: 'POSTS',
                value: postsAsync.asData?.value.toString() ?? '—',
              ),
              const SizedBox(width: 28),
              _Stat(label: 'COMMENTS', value: '—'),
              const SizedBox(width: 28),
              _Stat(label: 'SAVED', value: savedCount.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (_, _) => _FallbackAvatar(name: name, ac: ac),
          errorWidget: (_, _, _) => _FallbackAvatar(name: name, ac: ac),
        ),
      );
    }
    return _FallbackAvatar(name: name, ac: ac);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.name, required this.ac});
  final String name;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: ac.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: ac.textMuted,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.mono(
            base: theme.textTheme.labelSmall?.copyWith(
              color: ac.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile form card
// ---------------------------------------------------------------------------

class _ProfileFormCard extends ConsumerWidget {
  const _ProfileFormCard({
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
          _FieldLabel('DISPLAY NAME'),
          const SizedBox(height: 6),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('BIO'),
          const SizedBox(height: 6),
          TextField(
            controller: bioCtrl,
            maxLength: 300,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          _FieldLabel('UNIVERSITY'),
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
          _FieldLabel('DEPARTMENT'),
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
          _FieldLabel('ENROLLMENT YEAR'),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Text(
      text,
      style: AppTypography.mono(
        base: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ac.textMuted,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change password (UI only)
// ---------------------------------------------------------------------------

class _ChangePasswordCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
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
            'CHANGE PASSWORD',
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
          _FieldLabel('CURRENT PASSWORD'),
          const SizedBox(height: 6),
          const TextField(obscureText: true, decoration: InputDecoration()),
          const SizedBox(height: 16),
          _FieldLabel('NEW PASSWORD'),
          const SizedBox(height: 6),
          const TextField(obscureText: true, decoration: InputDecoration()),
          const SizedBox(height: 16),
          _FieldLabel('CONFIRM NEW PASSWORD'),
          const SizedBox(height: 6),
          const TextField(obscureText: true, decoration: InputDecoration()),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: ac.amber,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ac.amber.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
              ),
              child: const Text('Change Password'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connected accounts (UI only)
// ---------------------------------------------------------------------------

class _ConnectedAccountsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
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
            'CONNECTED ACCOUNTS',
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
          const SizedBox(height: 12),
          _AccountRow(provider: 'Google', connected: true),
          const SizedBox(height: 12),
          _AccountRow(provider: 'Microsoft', connected: false),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.provider, required this.connected});
  final String provider;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider, style: theme.textTheme.titleSmall),
              if (connected)
                Text(
                  'Connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ac.textMuted,
                  ),
                ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: null,
          child: Text(connected ? 'Unlink' : 'Link'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance section
// ---------------------------------------------------------------------------

class _AppearanceSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final selectedThemeId = ref.watch(themeProvider);
    final fontSize = ref.watch(fontSizeProvider);

    final themes = AppThemes.all.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'APPEARANCE',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: ac.textMuted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Theme', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: themes.length,
          itemBuilder: (context, i) {
            final t = themes[i];
            final isSelected = t.id == selectedThemeId;
            return GestureDetector(
              onTap: () => ref.read(themeProvider.notifier).setTheme(t.id),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? ac.amber : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ThemePreview(themeData: t)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.name,
                              style: theme.textTheme.labelMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: isSelected ? ac.amber : ac.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Font Size', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FontSizeButton(
                label: 'a',
                selected: fontSize == AppFontSize.normal,
                onTap: () =>
                    ref.read(fontSizeProvider.notifier).set(AppFontSize.normal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FontSizeButton(
                label: 'A',
                large: true,
                selected: fontSize == AppFontSize.large,
                onTap: () =>
                    ref.read(fontSizeProvider.notifier).set(AppFontSize.large),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          fontSize == AppFontSize.normal ? 'Normal' : 'Normal-Large',
          style: theme.textTheme.bodySmall?.copyWith(color: ac.textMuted),
        ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.themeData});
  final AppThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      child: CustomPaint(painter: _ThemePreviewPainter(themeData)),
    );
  }
}

class _ThemePreviewPainter extends CustomPainter {
  _ThemePreviewPainter(this.t);
  final AppThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = t.background;
    canvas.drawRect(Offset.zero & size, bg);

    final sidebarW = size.width * 0.28;
    final sidebar = Paint()..color = t.muted;
    canvas.drawRect(Rect.fromLTWH(0, 0, sidebarW, size.height), sidebar);

    final accentP = Paint()..color = t.amber;
    final r = Paint()
      ..color = t.mutedForeground.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final lx = sidebarW + 8;
    final lw = size.width - lx - 8;
    for (int i = 0; i < 3; i++) {
      final y = 8.0 + i * 10;
      final w = i == 0 ? lw : lw * (i == 1 ? 0.7 : 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lx, y, w, 4),
          const Radius.circular(2),
        ),
        r,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx, 38, lw * 0.4, 5),
        const Radius.circular(2),
      ),
      accentP,
    );

    final dot = Paint()..color = t.amber;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(sidebarW * 0.3, 12.0 + i * 14), 3, dot);
    }
  }

  @override
  bool shouldRepaint(_ThemePreviewPainter old) => old.t != t;
}

class _FontSizeButton extends StatelessWidget {
  const _FontSizeButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.large = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: selected ? ac.amberSubtle : null,
          border: Border.all(
            color: selected ? ac.amber : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: large ? 22 : 14,
            color: selected ? ac.amber : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Danger zone (UI only)
// ---------------------------------------------------------------------------

class _DangerZoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DANGER ZONE',
            style: AppTypography.mono(
              base: theme.textTheme.labelSmall?.copyWith(
                color: cs.error,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: cs.error.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          _DangerRow(
            title: 'Download my data',
            subtitle:
                'Export a copy of your personal data (PDPA right to data portability).',
            actionLabel: 'Download',
            destructive: false,
          ),
          const SizedBox(height: 16),
          _DangerRow(
            title: 'Remove encryption keys',
            subtitle:
                'Wipe your encryption keys from this device and the server.',
            actionLabel: 'Remove keys',
            destructive: true,
          ),
          const SizedBox(height: 16),
          _DangerRow(
            title: 'Delete account',
            subtitle:
                'Permanently delete your account and all associated data.',
            actionLabel: 'Delete',
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.destructive,
  });
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).extension<AppColors>()!.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? cs.error : null,
            foregroundColor: destructive ? cs.onError : null,
            disabledBackgroundColor: destructive ? cs.error : null,
            disabledForegroundColor: destructive ? cs.onError : null,
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Provider: user post count
// ---------------------------------------------------------------------------

final _userPostsCountProvider = StreamProvider.family<int, String>((ref, uid) {
  final repo = ref.watch(postRepositoryProvider);
  return repo.watchPostsByAuthor(uid).map((posts) => posts.length);
});
