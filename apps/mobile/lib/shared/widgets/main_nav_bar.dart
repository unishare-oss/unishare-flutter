import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/core/router/router.dart';

class MainNavBar extends StatelessWidget {
  const MainNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
    this.notificationsBadgeCount,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;

  /// Reserved for future badge wiring to the notifications Firestore collection.
  /// null = no badge rendered. Non-null and > 0 = badge shown on NOTIFS icon.
  final int? notificationsBadgeCount;

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
            children: NavTab.values.map((tab) {
              final index = tab.index;
              return Expanded(
                child: _NavTabItem(
                  tab: tab,
                  isActive: index == activeIndex,
                  onTap: () => onTap(index),
                  badgeCount: tab == NavTab.notifs
                      ? notificationsBadgeCount
                      : null,
                  colors: colors,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.colors,
    this.badgeCount,
  });

  final NavTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final AppColors colors;
  final int? badgeCount;

  IconData get _icon {
    switch (tab) {
      case NavTab.feed:
        return isActive ? Icons.home : Icons.home_outlined;
      case NavTab.posts:
        return isActive ? Icons.article : Icons.article_outlined;
      case NavTab.notifs:
        return isActive ? Icons.notifications : Icons.notifications_outlined;
      case NavTab.more:
        return Icons.menu;
    }
  }

  String get _label {
    switch (tab) {
      case NavTab.feed:
        return 'FEED';
      case NavTab.posts:
        return 'POSTS';
      case NavTab.notifs:
        return 'NOTIFS';
      case NavTab.more:
        return 'MORE';
    }
  }

  // Sentence case so screen readers pronounce the full word, not spell it out.
  String get _semanticsLabel {
    switch (tab) {
      case NavTab.feed:
        return 'Feed';
      case NavTab.posts:
        return 'Posts';
      case NavTab.notifs:
        return 'Notifications';
      case NavTab.more:
        return 'More';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isActive ? colors.amber : colors.textMuted;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 0.55,
      color: color,
    );

    Widget iconWidget = Icon(_icon, color: color, size: 24);

    if (tab == NavTab.notifs && badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(label: Text('$badgeCount'), child: iconWidget);
    }

    return Semantics(
      label: _semanticsLabel,
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
            iconWidget,
            const SizedBox(height: 2),
            Text(_label, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
