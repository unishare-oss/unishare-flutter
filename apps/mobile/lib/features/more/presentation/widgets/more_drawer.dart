import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_grid.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_user_row.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// Shows the More drawer as a modal bottom sheet. Auth-only.
Future<void> showMoreDrawer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (_) => const MoreDrawerSheet(),
  );
}

class MoreDrawerSheet extends ConsumerWidget {
  const MoreDrawerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final userAsync = ref.watch(currentUserProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DragHandle(),
            const _SpecularTopEdge(),
            const _Header(),
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            userAsync.when(
              data: (user) => user == null
                  ? const SizedBox.shrink()
                  : MoreDrawerUserRow(user: user),
              loading: () => const _UserRowSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            MoreDrawerGrid(
              onSavedTap: () => _go(context, '/saved'),
              onDepartmentsTap: () => _go(context, '/departments'),
              onRequestsTap: () => _go(context, '/requests'),
              onProfileTap: () => _go(context, '/profile'),
            ),
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            _SignOutRow(
              onTap: () => _signOut(context, ref),
              errorColor: cs.error,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: cs.error,
              ),
            ),
            SizedBox(height: 12 + bottomInset),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.go(path);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Capture providers before popping — the modal's ConsumerWidget is torn
    // down by the pop, after which `ref` reads can warn.
    final signOut = ref.read(signOutUseCaseProvider);
    final guestMode = ref.read(guestModeProvider.notifier);
    Navigator.of(context).pop();
    await signOut.call();
    guestMode.exit();
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 20,
      child: Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SpecularTopEdge extends StatelessWidget {
  const _SpecularTopEdge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: isDark ? 0.22 : 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ac = theme.extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ac.amber,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              'U',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Unishare',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  const _SignOutRow({
    required this.onTap,
    required this.errorColor,
    required this.labelStyle,
  });

  final VoidCallback onTap;
  final Color errorColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.logout_rounded, size: 18, color: errorColor),
            ),
            const SizedBox(width: 12),
            Text('Sign out', style: labelStyle),
          ],
        ),
      ),
    );
  }
}

class _UserRowSkeleton extends StatelessWidget {
  const _UserRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 68);
  }
}
