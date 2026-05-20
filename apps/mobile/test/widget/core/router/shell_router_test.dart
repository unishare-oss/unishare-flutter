import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/guest_mode_provider.dart';
import 'package:unishare_mobile/features/post/domain/entities/post_draft.dart';
import 'package:unishare_mobile/features/post/presentation/providers/draft_queue_provider.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

const _fakeUser = AppUser(id: 'u1', name: 'Test', email: 'test@test.com');

/// Returns the [GoRouter] instance from a pumped widget tree by reading it
/// from the [ProviderScope]'s container. Uses the [Consumer] element as the
/// context, which is a direct child of [ProviderScope].
GoRouter _router(WidgetTester tester) {
  // The router's StatefulShellRoute also uses a Consumer, so there are multiple
  // in the tree. The outermost one (first in traversal) is always inside the
  // ProviderScope from _buildApp, which is what we need.
  final consumerEl = tester.element(find.byType(Consumer).first);
  final container = ProviderScope.containerOf(consumerEl);
  return container.read(routerProvider);
}

Widget _buildApp({bool authenticated = true}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(
        (_) => authenticated ? Stream.value(_fakeUser) : const Stream.empty(),
      ),
      guestModeProvider.overrideWithValue(false),
      // Stub out Hive-backed draft queue so CreatePostScreen renders without
      // requiring Hive.openBox() in tests.
      draftQueueProvider.overrideWithValue(<PostDraft>[]),
    ],
    child: Consumer(
      builder: (ctx, ref, child) => MaterialApp.router(
        theme: AppTheme.build(AppThemes.unishare),
        routerConfig: ref.watch(routerProvider),
      ),
    ),
  );
}

void main() {
  group('Shell router', () {
    testWidgets('MainNavBar present on /feed (authenticated)', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.byType(MainNavBar), findsOneWidget);
    });

    testWidgets('MainNavBar present on /posts', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      _router(tester).go('/posts');
      await tester.pumpAndSettle();
      expect(find.byType(MainNavBar), findsOneWidget);
    });

    testWidgets('MainNavBar present on /notifications', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      _router(tester).go('/notifications');
      await tester.pumpAndSettle();
      expect(find.byType(MainNavBar), findsOneWidget);
    });

    testWidgets(
      'navigating to /more redirects to /feed (no longer a valid path)',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();
        _router(tester).go('/more');
        await tester.pumpAndSettle();
        expect(find.byType(MainNavBar), findsOneWidget);
        expect(find.text('Feed'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('MainNavBar absent on /welcome (unauthenticated)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(authenticated: false));
      await tester.pumpAndSettle();
      expect(find.byType(MainNavBar), findsNothing);
    });

    testWidgets('MainNavBar absent on /posts/create', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      _router(tester).go('/posts/create');
      await tester.pumpAndSettle();
      expect(find.byType(MainNavBar), findsNothing);
    });

    testWidgets('unknown path redirects to /feed', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      _router(tester).go('/nonexistent-xyz');
      await tester.pumpAndSettle();
      expect(find.byType(MainNavBar), findsOneWidget);
      // 'Feed' appears as both screen title and nav tab label.
      expect(find.text('Feed'), findsAtLeastNWidgets(1));
    });

    testWidgets('back press on POSTS branch navigates to FEED', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      _router(tester).go('/posts');
      await tester.pumpAndSettle();
      expect(find.text('My Posts'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 'My Posts' is gone (back press worked) and 'Feed' page is showing.
      expect(find.text('My Posts'), findsNothing);
      expect(find.text('Feed'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping active FEED tab does not throw', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      final feedTab = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == 'Feed',
      );
      expect(feedTab, findsOneWidget);
      await tester.tap(feedTab);
      await tester.pump();
      expect(find.byType(MainNavBar), findsOneWidget);
    });

    testWidgets(
      'tapping More tab opens the More drawer (does not switch branch)',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        final moreTab = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'More',
        );
        expect(moreTab, findsOneWidget);

        await tester.tap(moreTab);
        await tester.pumpAndSettle();

        // The drawer surfaces these uppercase labels. Profile moved to
        // the tappable user-row at the top of the drawer (SPEC-0011), so
        // it's no longer a tile here.
        expect(find.text('SAVED'), findsOneWidget);
        expect(find.text('DEPARTMENTS'), findsOneWidget);
        expect(find.text('REQUESTS'), findsOneWidget);
        expect(find.text('ACHIEVEMENTS'), findsOneWidget);
        // We're still rooted on /feed under the drawer.
        expect(find.byType(MainNavBar), findsOneWidget);
      },
    );

    testWidgets('on /saved the 4th nav slot reports Saved as Semantics value', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      _router(tester).go('/saved');
      await tester.pumpAndSettle();

      // Nav bar still present on the drawer destination.
      expect(find.byType(MainNavBar), findsOneWidget);

      // The 4th slot's semantics: label stays 'More' (the action), and
      // the current sub-destination is exposed as `value` so the tap
      // action remains accurate while the page state is announced.
      final moreTab = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == 'More' &&
            w.properties.value == 'Saved',
      );
      expect(moreTab, findsOneWidget);
    });
  });
}
