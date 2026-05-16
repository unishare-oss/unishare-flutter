import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/core/router/shell_scaffold.dart';
import 'package:unishare_mobile/shared/widgets/guest_nav_bar.dart';
import 'package:unishare_mobile/shared/widgets/scroll_to_top_target.dart';

class GuestShellScaffold extends StatelessWidget {
  const GuestShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final isOnFeed = path == '/feed' || path.startsWith('/feed/');
    final isOnSaved = path == '/saved';
    return PopScope(
      canPop: isOnFeed || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isOnFeed) {
          context.go('/feed');
        }
      },
      // `extendBody: true` lets content scroll behind the glass nav bar.
      // Each screen is responsible for adding `GuestNavBar.bottomInset` to
      // its scrollable's bottom padding.
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: GuestNavBar(
          isOnFeed: isOnFeed,
          isOnSaved: isOnSaved,
          onFeedTap: () {
            if (isOnFeed) {
              final state = ShellScaffold
                  .scrollTargetKeys[NavTab.feed.index]
                  .currentState;
              if (state is ScrollToTopTarget) {
                (state as ScrollToTopTarget).scrollToTop();
              }
              return;
            }
            context.go('/feed');
          },
          onSavedTap: () => context.go('/saved'),
        ),
      ),
    );
  }
}
