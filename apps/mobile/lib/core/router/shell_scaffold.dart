import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/scroll_to_top_target.dart';
import 'router.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// One `GlobalKey<State>` per tab branch. Cast `currentState` to
  /// `ScrollToTopTarget` to call `scrollToTop()` without coupling the shell
  /// to any concrete screen class.
  static final List<GlobalKey<State>> scrollTargetKeys = List.generate(
    NavTab.values.length,
    (_) => GlobalKey<State>(),
  );

  @override
  Widget build(BuildContext context) {
    // TODO(flutter-engineer): implement per SPEC-0005.
    // Wire PopScope for Android back-button:
    //   canPop: navigationShell.currentIndex == NavTab.feed.index
    //   onPopInvokedWithResult: if !didPop → goBranch(NavTab.feed.index, initialLocation: true)
    throw UnimplementedError();
  }

  void handleTabTap(int index) {
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
