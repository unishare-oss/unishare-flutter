import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/widgets/unishare_logo.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_grid.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_user_row.dart';
import 'package:unishare_mobile/shared/widgets/confirm_sign_out_dialog.dart';

/// Shows the More drawer as a modal bottom sheet. Auth-only.
Future<void> showMoreDrawer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => const MoreDrawerSheet(),
  );
}

class MoreDrawerSheet extends ConsumerWidget {
  const MoreDrawerSheet({super.key});

  // Glass shape uniform radius. Top corners read rounded; bottom rounded
  // corners are pushed below the visible bounds via [_glassOverflowBelow]
  // and hidden by the outer ClipRRect.
  static const double _sheetRadius = 28;
  static const double _glassOverflowBelow = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(_sheetRadius),
      ),
      child: LiquidGlassLayer(
        settings: LiquidGlassSettings(
          thickness: isDark ? 16 : 18,
          blur: isDark ? 6 : 10,
          refractiveIndex: 1.18,
          // Light mode sits on a bright/varied backdrop with only a 0.35
          // barrier — a much denser tint is needed for the sheet to read as
          // a surface. Dark mode keeps the subtle nav-bar treatment since
          // the dark scaffold gives plenty of contrast.
          glassColor: isDark
              ? const Color(0x1FFFFFFF)
              : const Color(0xB3FFFFFF),
          lightIntensity: isDark ? 0.6 : 0.55,
          chromaticAberration: 0.04,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Soft drop shadow above the top edge so the sheet lifts off
              // the dimmed page behind it.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.45 : 0.18,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Glass surface — extends below the visible bounds so its
              // rounded bottom corners are hidden by the outer ClipRRect.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: -_glassOverflowBelow,
                child: const LiquidGlass(
                  shape: LiquidRoundedSuperellipse(borderRadius: _sheetRadius),
                  child: SizedBox.expand(),
                ),
              ),
              // Content sits above the glass.
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DragHandle(),
                  const _SpecularTopEdge(),
                  const _Header(),
                  userAsync.when(
                    data: (user) => user == null
                        ? const SizedBox.shrink()
                        : MoreDrawerUserRow(user: user),
                    loading: () => const _UserRowSkeleton(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  MoreDrawerGrid(
                    onSavedTap: () => _go(context, '/saved'),
                    onDepartmentsTap: () => _go(context, '/departments'),
                    onRequestsTap: () => _go(context, '/requests'),
                    onAchievementsTap: () {
                      final uid = userAsync.asData?.value?.id;
                      if (uid == null) return;
                      _go(context, '/achievements/$uid');
                    },
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String path) {
    // Capture the router before popping — the modal's context can become
    // deactivated as the sheet tears down, breaking InheritedWidget lookups.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(path);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Capture messenger before the first async gap — it lives above the drawer
    // in the widget tree and remains valid after the sheet is dismissed.
    final messenger = ScaffoldMessenger.of(context);

    if (!await confirmSignOut(context)) return;

    // Capture providers before popping — the modal's ConsumerWidget is torn
    // down by the pop, after which `ref` reads can warn.
    final signOut = ref.read(signOutUseCaseProvider);
    final guestMode = ref.read(guestModeProvider.notifier);
    if (context.mounted) Navigator.of(context).pop();
    try {
      await signOut.call();
      guestMode.exit();
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    }
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: UnishareLogo(iconSize: 28, fontSize: 17),
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
