import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

class GuestNavBar extends StatefulWidget {
  const GuestNavBar({
    super.key,
    required this.isOnFeed,
    required this.isOnSaved,
    required this.onFeedTap,
    required this.onSavedTap,
  });

  /// True when the current route is `/feed` (or its descendants).
  final bool isOnFeed;

  /// True when the current route is `/saved`.
  final bool isOnSaved;

  final VoidCallback onFeedTap;
  final VoidCallback onSavedTap;

  static const double _barHeight = 64;
  static const double _hMargin = 16;
  static const double _bottomGap = 12;
  static const double _pillVPad = 10;
  static const double _pillHPad = 8;
  static const double _barRadius = 32;
  static const double _pillRadius = 22;

  /// Bottom inset that pages must reserve so their content isn't hidden
  /// behind the floating nav bar. Excludes system safe area.
  static const double bottomInset = _barHeight + _bottomGap;

  /// Drag-snap is limited to "real" branches — Feed (0) and Saved (1).
  /// Sign In (index 2) is a one-shot action, not a destination.
  static const int _draggableTabCount = 2;

  @override
  State<GuestNavBar> createState() => _GuestNavBarState();
}

class _GuestNavBarState extends State<GuestNavBar> {
  double? _dragLeft;
  int? _hoveredTab; // 0 = Feed, 1 = Saved (only draggable targets)

  int get _selectedTab {
    if (widget.isOnFeed) return 0;
    if (widget.isOnSaved) return 1;
    return -1;
  }

  void _onTab(int tab) {
    switch (tab) {
      case 0:
        widget.onFeedTap();
      case 1:
        widget.onSavedTap();
      case 2:
        context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final selected = _selectedTab;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        GuestNavBar._hMargin,
        0,
        GuestNavBar._hMargin,
        GuestNavBar._bottomGap + safeBottom,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          const tabCount = 3;
          final tabWidth = barWidth / tabCount;
          final pillWidth = tabWidth - GuestNavBar._pillHPad * 2;
          final pillHeight = GuestNavBar._barHeight - GuestNavBar._pillVPad * 2;

          final effectiveTab = _hoveredTab ?? selected;
          final restingLeft = selected >= 0
              ? tabWidth * selected + GuestNavBar._pillHPad
              : 0.0;
          final pillLeft = _dragLeft ?? restingLeft;
          final isDragging = _dragLeft != null;

          final tabs = [
            _GuestTab(
              icon: effectiveTab == 0
                  ? Icons.home_rounded
                  : Icons.home_outlined,
              label: 'Feed',
              semanticsLabel: 'Feed',
              isActive: effectiveTab == 0,
              onTap: isDragging ? null : widget.onFeedTap,
              ac: ac,
            ),
            _GuestTab(
              icon: effectiveTab == 1
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: 'Saved',
              semanticsLabel: 'Saved posts',
              isActive: effectiveTab == 1,
              onTap: isDragging ? null : widget.onSavedTap,
              ac: ac,
            ),
            _GuestTab(
              icon: Icons.person_outline_rounded,
              label: 'Sign In',
              semanticsLabel: 'Sign in',
              isActive: false,
              onTap: isDragging ? null : () => context.go('/welcome'),
              ac: ac,
            ),
          ];

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
              height: GuestNavBar._barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            GuestNavBar._barRadius,
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
                  const Positioned.fill(
                    child: LiquidGlass(
                      shape: LiquidRoundedSuperellipse(
                        borderRadius: GuestNavBar._barRadius,
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
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
                  // Pill — visual, below tabs (so its glass doesn't refract them).
                  if (selected >= 0)
                    AnimatedPositioned(
                      duration: isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: GuestNavBar._pillVPad,
                      width: pillWidth,
                      height: pillHeight,
                      child: IgnorePointer(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: isDragging ? 1.0 : 0.0),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutBack,
                          builder: (context, t, _) {
                            final scale = 1.0 + 0.65 * t;
                            return Transform.scale(
                              scale: scale,
                              child: _ActivePill(
                                ac: ac,
                                isDark: isDark,
                                radius: GuestNavBar._pillRadius,
                                dragProgress: t,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  // Tab buttons — above pill, never refracted.
                  Positioned.fill(
                    child: Row(
                      children: tabs.map((t) => Expanded(child: t)).toList(),
                    ),
                  ),
                  // Drag overlay — invisible, captures drag + tap-on-pill.
                  if (selected >= 0)
                    AnimatedPositioned(
                      duration: isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: GuestNavBar._pillVPad,
                      width: pillWidth,
                      height: pillHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onTab(selected),
                        onHorizontalDragStart: (_) => _onDragStart(restingLeft),
                        onHorizontalDragUpdate: (details) => _onDragUpdate(
                          details,
                          tabWidth: tabWidth,
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
      _hoveredTab = _selectedTab.clamp(0, GuestNavBar._draggableTabCount - 1);
    });
  }

  void _onDragUpdate(
    DragUpdateDetails details, {
    required double tabWidth,
    required double pillWidth,
  }) {
    // Drag range is the first N tabs (Feed + Saved). Sign In is excluded.
    final minLeft = GuestNavBar._pillHPad;
    final maxLeft =
        tabWidth * (GuestNavBar._draggableTabCount - 1) + GuestNavBar._pillHPad;
    final nextLeft = ((_dragLeft ?? minLeft) + details.delta.dx).clamp(
      minLeft,
      maxLeft,
    );

    final pillCenter = nextLeft + pillWidth / 2;
    final nextHovered = (pillCenter / tabWidth).floor().clamp(
      0,
      GuestNavBar._draggableTabCount - 1,
    );

    setState(() {
      _dragLeft = nextLeft;
      if (nextHovered != _hoveredTab) {
        HapticFeedback.selectionClick();
        _hoveredTab = nextHovered;
      }
    });
  }

  void _onDragEnd() {
    final snapTab = _hoveredTab;
    setState(() {
      _dragLeft = null;
      _hoveredTab = null;
    });
    if (snapTab != null && snapTab != _selectedTab) {
      _onTab(snapTab);
    }
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill({
    required this.ac,
    required this.isDark,
    required this.radius,
    required this.dragProgress,
  });

  final AppColors ac;
  final bool isDark;
  final double radius;

  /// 0 at rest, 1 while held. May briefly exceed 1 during the easeOutBack
  /// overshoot — clamp before using in physical-value lerps.
  final double dragProgress;

  @override
  Widget build(BuildContext context) {
    final t = dragProgress.clamp(0.0, 1.0);
    final blur = 2.0 + 10.0 * t;
    final aberration = 0.05 + 0.10 * t;
    final thickness = 22.0 + 8.0 * t;
    final glowBlur = 22.0 + 18.0 * t;
    final glowAlpha = (isDark ? 0.40 : 0.22) + (isDark ? 0.30 : 0.22) * t;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: ac.amber.withValues(alpha: glowAlpha),
            blurRadius: glowBlur,
            spreadRadius: -2,
          ),
        ],
      ),
      child: LiquidGlass.withOwnLayer(
        shape: LiquidRoundedSuperellipse(borderRadius: radius),
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

class _GuestTab extends StatelessWidget {
  const _GuestTab({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.isActive,
    required this.onTap,
    required this.ac,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final bool isActive;
  final VoidCallback? onTap;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? ac.amber : ac.textMuted;

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
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
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
