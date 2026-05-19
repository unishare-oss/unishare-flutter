import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer.dart';
import 'package:unishare_mobile/features/notifications/presentation/providers/unread_count_provider.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

class ShellScaffold extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = navigationShell.currentIndex;
    final currentPath = GoRouterState.of(context).uri.path;
    final me = ref.watch(authStateProvider).asData?.value?.id;
    // Re-route cross-user `/achievements/:uid` and `/profile/:uid` to the
    // generic "Viewing" slot so the navbar doesn't claim "Achievements"
    // or "Profile" — those should mean the user's own destinations.
    var currentSub = DrawerDestination.fromPath(currentPath);
    final crossUserMatch = RegExp(
      r'^/(profile|achievements)/([^/]+)$',
    ).firstMatch(currentPath);
    final isCrossUser = crossUserMatch != null && crossUserMatch.group(2) != me;
    if (isCrossUser) {
      currentSub = DrawerDestination.publicProfile;
    }
    // When the user pushed a route that *lives in* the drawer-destinations
    // branch (Branch 3) but pushed it on top of another branch (typically
    // Feed), `navigationShell.currentIndex` stays at the original branch.
    // Override the visual pill to point at the 4th slot so users see "I'm
    // on a sub-destination" without breaking back-stack semantics.
    final displayedIndex =
        (currentSub != null && activeIndex != NavTab.more.index)
        ? NavTab.more.index
        : null;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

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
          displayedIndex: displayedIndex,
          onTap: (index) => _handleTabTap(context, index),
          currentSubDestination: currentSub,
          notificationsBadgeCount: unreadCount,
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
    // Feed acts as a global "home" — always reset and return to /feed
    // regardless of which branch we're on or what's pushed on top.
    if (index == NavTab.feed.index) {
      context.go('/feed');
      return;
    }
    if (index == navigationShell.currentIndex) {
      // If the active branch has a pushed route on top (e.g., user pushed
      // /profile/:uid from feed), tapping the tab should pop back to the
      // branch root rather than scroll-to-top a screen that isn't visible.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      final state = scrollTargetKeys[index].currentState;
      if (state is ScrollToTopTarget) {
        (state as ScrollToTopTarget).scrollToTop();
      }
      return;
    }
    navigationShell.goBranch(index);
  }
}
