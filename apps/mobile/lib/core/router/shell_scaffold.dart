import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';
import 'package:unishare_mobile/core/router/router.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final List<GlobalKey<State>> scrollTargetKeys = List.generate(
    NavTab.values.length + 1, // auth tabs + guest /saved branch
    (_) => GlobalKey<State>(),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Allow pop when GoRouter has a route to pop (e.g. /more/profile → /more)
      // or when already on FEED root (system pop exits the app on Android).
      canPop:
          navigationShell.currentIndex == NavTab.feed.index || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && navigationShell.currentIndex != NavTab.feed.index) {
          navigationShell.goBranch(NavTab.feed.index, initialLocation: true);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: MainNavBar(
          activeIndex: navigationShell.currentIndex,
          onTap: _handleTabTap,
        ),
      ),
    );
  }

  void _handleTabTap(int index) {
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
