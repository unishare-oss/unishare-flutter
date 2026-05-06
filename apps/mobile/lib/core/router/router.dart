import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:unishare_mobile/features/departments/presentation/screens/departments_screen.dart';
import 'package:unishare_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:unishare_mobile/features/more/presentation/screens/more_screen.dart';
import 'package:unishare_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';
import 'package:unishare_mobile/features/post/presentation/screens/create_post_screen.dart';
import 'package:unishare_mobile/features/post/presentation/screens/my_posts_screen.dart';
import 'package:unishare_mobile/features/post/presentation/screens/post_detail_screen.dart';
import 'package:unishare_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:unishare_mobile/features/requests/presentation/screens/requests_screen.dart';
import 'package:unishare_mobile/features/saved/presentation/screens/saved_screen.dart';
import 'package:unishare_mobile/core/router/shell_scaffold.dart';

part 'router.g.dart';

// ---------------------------------------------------------------------------
// NavTab — branch index order must match StatefulShellRoute.branches order
// ---------------------------------------------------------------------------

// Simple in-memory flag — not a Riverpod provider to keep it out of codegen.
bool academicProfileSessionDismissed = false;

enum NavTab {
  feed,
  posts,
  notifs,
  more;

  String get rootPath {
    switch (this) {
      case NavTab.feed:
        return '/feed';
      case NavTab.posts:
        return '/posts';
      case NavTab.notifs:
        return '/notifications';
      case NavTab.more:
        return '/more';
    }
  }
}

// ---------------------------------------------------------------------------
// Notifier — watches auth + guest state, calls notifyListeners on change
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<Object?>>(
      authStateProvider,
      (prev, next) => notifyListeners(),
    );
    _ref.listen<bool>(guestModeProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final isGuest = _ref.read(guestModeProvider);

    // Hold all redirects while Firebase is still restoring the session.
    // Without this, every deep link fires before auth resolves and the user
    // lands on /welcome, losing the original URL intent.
    if (!authAsync.hasValue) return null;

    final isAuthenticated = authAsync.value != null;

    const authRoutes = {'/welcome'};
    final currentPath = state.uri.path;

    // 1. No session + not guest → force /welcome
    if (!isAuthenticated && !isGuest) {
      if (!authRoutes.contains(currentPath)) {
        return '/welcome';
      }
      return null;
    }

    // 2. Authenticated on an auth route → go to /feed
    if (isAuthenticated && authRoutes.contains(currentPath)) {
      return '/feed';
    }

    // 3. Legacy root → /feed
    if (currentPath == '/') {
      return '/feed';
    }

    // 4. Unknown path → /feed
    // authRoutes covers /welcome as exact-match only (no child routes exist).
    // knownPrefixes covers shell branches and their nested children.
    const knownPrefixes = {'/feed', '/posts', '/notifications', '/more'};
    final isKnown =
        authRoutes.contains(currentPath) ||
        knownPrefixes.any(
          (p) => currentPath == p || currentPath.startsWith('$p/'),
        );
    if (!isKnown) {
      return '/feed';
    }

    return null;
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

@riverpod
GoRouter router(Ref ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/posts/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/posts/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final seed = state.extra as Post?;
          return PostDetailScreen(postId: postId, seed: seed);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          // Branch 0 — FEED
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => FeedScreen(
                  scrollKey: ShellScaffold.scrollTargetKeys[NavTab.feed.index],
                ),
              ),
            ],
          ),
          // Branch 1 — POSTS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/posts',
                builder: (context, state) => MyPostsScreen(
                  scrollKey: ShellScaffold.scrollTargetKeys[NavTab.posts.index],
                ),
              ),
            ],
          ),
          // Branch 2 — NOTIFS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => NotificationsScreen(
                  scrollKey:
                      ShellScaffold.scrollTargetKeys[NavTab.notifs.index],
                ),
              ),
            ],
          ),
          // Branch 3 — MORE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => MoreScreen(
                  scrollKey: ShellScaffold.scrollTargetKeys[NavTab.more.index],
                ),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: 'saved',
                    builder: (context, state) => const SavedScreen(),
                  ),
                  GoRoute(
                    path: 'departments',
                    builder: (context, state) => const DepartmentsScreen(),
                  ),
                  GoRoute(
                    path: 'requests',
                    builder: (context, state) => const RequestsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
