import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// One scroll target per branch: Feed (0), Posts (1), Notifs (2), and the
  /// drawer-destinations branch (3). Branch 3's slot is unused — the 4th tab
  /// opens the drawer instead of scrolling — but keeping it in the list lets
  /// `scrollTargetKeys[index]` stay safe for every NavTab index.
  static final List<GlobalKey<State>> scrollTargetKeys = List.generate(
    NavTab.values.length,
    (_) => GlobalKey<State>(),
  );

  @override
  Widget build(BuildContext context) {
    final activeIndex = navigationShell.currentIndex;
    final currentPath = GoRouterState.of(context).uri.path;
    final currentSub = DrawerDestination.fromPath(currentPath);

    return PopScope(
      canPop: activeIndex == NavTab.feed.index || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && activeIndex != NavTab.feed.index) {
          navigationShell.goBranch(NavTab.feed.index, initialLocation: true);
        }
      },
      // `extendBody: true` lets each screen's scrollable extend behind the
      // glass nav bar so the bar refracts scrolled content. Each branch
      // screen is responsible for adding `MainNavBar.bottomInset` to its
      // scrollable's bottom padding so the final item can scroll up above
      // the bar instead of being permanently clipped.
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: MainNavBar(
          activeIndex: activeIndex,
          onTap: (index) => _handleTabTap(context, index),
          currentSubDestination: currentSub,
        ),
      ),
    );
  }

  void _handleTabTap(BuildContext context, int index) {
    // More is an action tab — it opens the drawer instead of switching branch.
    if (index == NavTab.more.index) {
      showMoreDrawer(context);
      return;
    }
    if (index == navigationShell.currentIndex) {
      final state = scrollTargetKeys[index].currentState;
      if (state is ScrollToTopTarget) {
        (state as ScrollToTopTarget).scrollToTop();
      }
      return;
    }
    navigationShell.goBranch(index);
  }
}
