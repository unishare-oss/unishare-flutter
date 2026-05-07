import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/core/router/shell_scaffold.dart';
import 'package:unishare_mobile/shared/widgets/guest_nav_bar.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

/// Branch index of the /saved route in the StatefulShellRoute.
const kSavedBranchIndex = 4;

class GuestShellScaffold extends StatelessWidget {
  const GuestShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isOnFeed = navigationShell.currentIndex == NavTab.feed.index;
    return PopScope(
      canPop: isOnFeed || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isOnFeed) {
          navigationShell.goBranch(NavTab.feed.index, initialLocation: true);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: GuestNavBar(
          activeIndex: navigationShell.currentIndex,
          onFeedTap: () => _handleTap(NavTab.feed.index),
          onSavedTap: () => _handleTap(kSavedBranchIndex),
        ),
      ),
    );
  }

  void _handleTap(int branchIndex) {
    if (branchIndex == navigationShell.currentIndex) {
      final state = ShellScaffold.scrollTargetKeys[branchIndex].currentState;
      if (state is ScrollToTopTarget) {
        (state as ScrollToTopTarget).scrollToTop();
      }
      return;
    }
    navigationShell.goBranch(branchIndex);
  }
}
