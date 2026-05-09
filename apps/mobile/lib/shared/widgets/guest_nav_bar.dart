import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class GuestNavBar extends StatelessWidget {
  const GuestNavBar({
    super.key,
    required this.activeIndex,
    required this.onFeedTap,
    required this.onSavedTap,
  });

  final int activeIndex;
  final VoidCallback onFeedTap;
  final VoidCallback onSavedTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final barBg = Theme.of(context).scaffoldBackgroundColor;
    final borderColor = Theme.of(context).dividerColor;

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: _GuestNavItem(
                  icon: activeIndex == NavTab.feed.index
                      ? Icons.home
                      : Icons.home_outlined,
                  label: 'FEED',
                  semanticsLabel: 'Feed',
                  isActive: activeIndex == NavTab.feed.index,
                  onTap: onFeedTap,
                  colors: colors,
                ),
              ),
              Expanded(
                child: _GuestNavItem(
                  icon: activeIndex == kSavedBranchIndex
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  label: 'SAVED',
                  semanticsLabel: 'Saved posts',
                  isActive: activeIndex == kSavedBranchIndex,
                  onTap: onSavedTap,
                  colors: colors,
                ),
              ),
              Expanded(
                child: _GuestNavItem(
                  icon: Icons.person_outline,
                  label: 'SIGN IN',
                  semanticsLabel: 'Sign in',
                  isActive: false,
                  onTap: () => context.go('/welcome'),
                  colors: colors,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestNavItem extends StatelessWidget {
  const _GuestNavItem({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.isActive,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final bool isActive;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? colors.amber : colors.textMuted;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      letterSpacing: 0.55,
      color: color,
    );
    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: isActive,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
