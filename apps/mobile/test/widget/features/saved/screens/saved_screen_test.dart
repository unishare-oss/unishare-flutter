import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post.dart';
import 'package:unishare_mobile/features/saved/domain/entities/saved_post_snapshot.dart';
import 'package:unishare_mobile/features/saved/presentation/providers/saved_posts_provider.dart';
import 'package:unishare_mobile/features/saved/presentation/screens/saved_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SavedScreen()),
    GoRoute(path: '/welcome', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/posts/:id', builder: (_, _) => const SizedBox()),
  ],
);

SavedPost _fakePost(String id) => SavedPost(
  postId: id,
  savedAt: DateTime(2024),
  snapshot: SavedPostSnapshot(
    title: 'Test Post $id',
    authorName: 'Alice',
    authorAvatar: '',
    courseId: 'CSC234',
    postType: 'lectureNote',
    tags: const [],
    commentsCount: 2,
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('shows AppBar title "Saved"', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPostsProvider.overrideWith((_) => Stream.value([])),
          guestModeProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(
          theme: AppTheme.build(AppThemes.unishare),
          routerConfig: _router(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('shows empty state when list is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPostsProvider.overrideWith((_) => Stream.value([])),
          guestModeProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(
          theme: AppTheme.build(AppThemes.unishare),
          routerConfig: _router(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No saved posts yet.'), findsOneWidget);
  });

  testWidgets('renders a card for each saved post', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPostsProvider.overrideWith(
            (_) => Stream.value([_fakePost('1'), _fakePost('2')]),
          ),
          guestModeProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(
          theme: AppTheme.build(AppThemes.unishare),
          routerConfig: _router(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test Post 1'), findsOneWidget);
    expect(find.text('Test Post 2'), findsOneWidget);
  });

  testWidgets('shows guest banner and sign-in link in guest mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPostsProvider.overrideWith((_) => Stream.value([])),
          guestModeProvider.overrideWithValue(true),
        ],
        child: MaterialApp.router(
          theme: AppTheme.build(AppThemes.unishare),
          routerConfig: _router(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Saved posts are stored locally'),
      findsOneWidget,
    );
    expect(find.text('→ Sign in to sync'), findsOneWidget);
  });

  testWidgets('shows error state with retry button on stream error', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPostsProvider.overrideWithValue(
            AsyncValue<List<SavedPost>>.error(
              Exception('network error'),
              StackTrace.empty,
            ),
          ),
          guestModeProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(
          theme: AppTheme.build(AppThemes.unishare),
          routerConfig: _router(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
