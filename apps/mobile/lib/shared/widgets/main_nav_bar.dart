import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class MainNavBar extends StatefulWidget {
  const MainNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
    this.notificationsBadgeCount,
    this.currentSubDestination,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;
  final int? notificationsBadgeCount;

  /// When set, the 4th nav slot renders this destination's label and icon
  /// instead of the default "More" / menu icon. Tap behaviour is unchanged
  /// — the 4th slot always fires `onTap(NavTab.more.index)`.
  final DrawerDestination? currentSubDestination;

  static const double _barHeight = 64;
  static const double _hMargin = 16;
  static const double _bottomGap = 12;
  static const double _pillVPad = 10;
  static const double _pillHPad = 8;
  static const double _barRadius = 32;
  static const double _pillRadius = 22;

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  /// Current pill left-offset while a drag is in progress. `null` means
  /// no drag — the pill follows `widget.activeIndex` via [AnimatedPositioned].
  double? _dragLeft;

  /// Index the pill is currently hovering over during a drag. Drives the
  /// preview icon/label state and the snap target on release.
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        MainNavBar._hMargin,
        0,
        MainNavBar._hMargin,
        MainNavBar._bottomGap + safeBottom,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final tabCount = NavTab.values.length;
          final tabWidth = barWidth / tabCount;
          final pillWidth = tabWidth - MainNavBar._pillHPad * 2;
          final pillHeight = MainNavBar._barHeight - MainNavBar._pillVPad * 2;

          final effectiveIndex = _hoveredIndex ?? widget.activeIndex;
          final restingLeft =
              tabWidth * widget.activeIndex + MainNavBar._pillHPad;
          final pillLeft = _dragLeft ?? restingLeft;
          final isDragging = _dragLeft != null;

          return LiquidGlassLayer(
            settings: LiquidGlassSettings(
              thickness: isDark ? 16 : 14,
              blur: 6,
              refractiveIndex: 1.18,
              glassColor: isDark
                  ? const Color(0x1FFFFFFF)
                  : const Color(0x26FFFFFF),
              lightIntensity: isDark ? 0.6 : 0.5,
              chromaticAberration: 0.04,
            ),
            child: SizedBox(
              height: MainNavBar._barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Drop shadow under bar
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MainNavBar._barRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.45 : 0.12,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Glass surface — whole bar
                  const Positioned.fill(
                    child: LiquidGlass(
                      shape: LiquidRoundedSuperellipse(
                        borderRadius: MainNavBar._barRadius,
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
                  // Specular top edge
                  Positioned(
                    top: 0,
                    left: 24,
                    right: 24,
                    height: 1,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(
                                alpha: isDark ? 0.22 : 0.7,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Active pill — visual only. Lives BELOW tabs so its glass
                  // doesn't refract the active tab's icon/label.
                  AnimatedPositioned(
                    duration: isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: pillLeft,
                    top: MainNavBar._pillVPad,
                    width: pillWidth,
                    height: pillHeight,
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: isDragging ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        builder: (context, t, _) {
                          // easeOutBack overshoots past `end`, giving the
                          // squishy "bounce" feel on both grab and release.
                          // 0.65 → pill peeks ~5px above and below the bar.
                          final scale = 1.0 + 0.65 * t;
                          return Transform.scale(
                            scale: scale,
                            child: _ActivePill(
                              ac: ac,
                              isDark: isDark,
                              dragProgress: t,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Tab buttons — on top of the pill so icons/labels stay crisp.
                  Positioned.fill(
                    child: Row(
                      children: NavTab.values.map((tab) {
                        return Expanded(
                          child: _NavTabItem(
                            tab: tab,
                            isActive: tab.index == effectiveIndex,
                            // Drag overlay swallows taps on the pill; the active
                            // tab fires from there. Suppress here during drag.
                            onTap: isDragging
                                ? null
                                : () => widget.onTap(tab.index),
                            badgeCount: tab == NavTab.notifs
                                ? widget.notificationsBadgeCount
                                : null,
                            subDestination: tab == NavTab.more
                                ? widget.currentSubDestination
                                : null,
                            ac: ac,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Drag overlay — invisible. Sits on top, follows the pill
                  // position, and captures the pan gesture + tap-on-pill.
                  AnimatedPositioned(
                    duration: isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: pillLeft,
                    top: MainNavBar._pillVPad,
                    width: pillWidth,
                    height: pillHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onTap(widget.activeIndex),
                      onHorizontalDragStart: (_) => _onDragStart(restingLeft),
                      onHorizontalDragUpdate: (details) => _onDragUpdate(
                        details,
                        tabWidth: tabWidth,
                        tabCount: tabCount,
                        barWidth: barWidth,
                        pillWidth: pillWidth,
                      ),
                      onHorizontalDragEnd: (_) => _onDragEnd(),
                      onHorizontalDragCancel: _onDragEnd,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onDragStart(double restingLeft) {
    HapticFeedback.selectionClick();
    setState(() {
      _dragLeft = restingLeft;
      _hoveredIndex = widget.activeIndex;
    });
  }

  void _onDragUpdate(
    DragUpdateDetails details, {
    required double tabWidth,
    required int tabCount,
    required double barWidth,
    required double pillWidth,
  }) {
    final minLeft = MainNavBar._pillHPad;
    final maxLeft = barWidth - pillWidth - MainNavBar._pillHPad;
    final nextLeft = ((_dragLeft ?? minLeft) + details.delta.dx).clamp(
      minLeft,
      maxLeft,
    );

    final pillCenter = nextLeft + pillWidth / 2;
    final nextHovered = (pillCenter / tabWidth).floor().clamp(0, tabCount - 1);

    setState(() {
      _dragLeft = nextLeft;
      if (nextHovered != _hoveredIndex) {
        HapticFeedback.selectionClick();
        _hoveredIndex = nextHovered;
      }
    });
  }

  void _onDragEnd() {
    final snapIndex = _hoveredIndex;
    setState(() {
      _dragLeft = null;
      _hoveredIndex = null;
    });
    if (snapIndex != null && snapIndex != widget.activeIndex) {
      widget.onTap(snapIndex);
    }
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill({
    required this.ac,
    required this.isDark,
    required this.dragProgress,
  });

  final AppColors ac;
  final bool isDark;

  /// 0 at rest, 1 while held. May briefly exceed 1 during the easeOutBack
  /// overshoot — clamp before using in physical-value lerps.
  final double dragProgress;

  @override
  Widget build(BuildContext context) {
    final t = dragProgress.clamp(0.0, 1.0);
    final blur = 2.0 + 10.0 * t; // 2 → 12 — frosted while held
    final aberration = 0.05 + 0.10 * t; // 0.05 → 0.15 — stronger rainbow edge
    final thickness = 22.0 + 8.0 * t; // 22 → 30 — denser glass when grabbed
    final glowBlur = 22.0 + 18.0 * t; // 22 → 40
    final glowAlpha = (isDark ? 0.40 : 0.22) + (isDark ? 0.30 : 0.22) * t;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MainNavBar._pillRadius),
        boxShadow: [
          BoxShadow(
            color: ac.amber.withValues(alpha: glowAlpha),
            blurRadius: glowBlur,
            spreadRadius: -2,
          ),
        ],
      ),
      child: LiquidGlass.withOwnLayer(
        shape: const LiquidRoundedSuperellipse(
          borderRadius: MainNavBar._pillRadius,
        ),
        settings: LiquidGlassSettings(
          thickness: thickness,
          blur: blur,
          refractiveIndex: 1.35,
          glassColor: ac.amber.withValues(alpha: isDark ? 0.30 : 0.22),
          lightIntensity: isDark ? 0.85 : 0.7,
          chromaticAberration: aberration,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.ac,
    this.badgeCount,
    this.subDestination,
  });

  final NavTab tab;
  final bool isActive;

  /// `null` disables tapping (used while a drag is in progress).
  final VoidCallback? onTap;
  final AppColors ac;
  final int? badgeCount;

  /// Only meaningful on the More tab. When non-null, the slot renders this
  /// destination's label + icon instead of the default "More" / menu icon.
  final DrawerDestination? subDestination;

  IconData get _icon {
    switch (tab) {
      case NavTab.feed:
        return isActive ? Icons.home_rounded : Icons.home_outlined;
      case NavTab.posts:
        return isActive ? Icons.article_rounded : Icons.article_outlined;
      case NavTab.notifs:
        return isActive
            ? Icons.notifications_rounded
            : Icons.notifications_outlined;
      case NavTab.more:
        return subDestination?.icon ?? Icons.menu_rounded;
    }
  }

  String get _label {
    switch (tab) {
      case NavTab.feed:
        return 'Feed';
      case NavTab.posts:
        return 'Posts';
      case NavTab.notifs:
        return 'Notifs';
      case NavTab.more:
        return subDestination?.label ?? 'More';
    }
  }

  String get _semanticsLabel {
    switch (tab) {
      case NavTab.feed:
        return 'Feed';
      case NavTab.posts:
        return 'Posts';
      case NavTab.notifs:
        return 'Notifications';
      case NavTab.more:
        return subDestination?.label ?? 'More';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? ac.amber : ac.textMuted;

    Widget iconWidget = Icon(_icon, color: color, size: 22);
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
            Text(
              _label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
