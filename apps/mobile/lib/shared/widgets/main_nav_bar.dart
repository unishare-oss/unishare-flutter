import 'package:flutter/material.dart';

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
    // TODO(flutter-engineer): implement per SPEC-0005.
    // Read colors from Theme.of(context).extension<AppColors>() — no hardcoded hex.
    // Read typography from AppTypography — no direct GoogleFonts calls.
    // Build a Row of _NavTabItem for each NavTab.values entry.
    throw UnimplementedError();
  }
}
