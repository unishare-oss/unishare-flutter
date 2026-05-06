import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/more/presentation/screens/more_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

void main() {
  Widget buildSubject() {
    final scrollKey = GlobalKey<State>();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/more',
          builder: (ctx, _) => MoreScreen(scrollKey: scrollKey),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (ctx, _) => const Scaffold(body: Text('Profile page')),
            ),
            GoRoute(
              path: 'saved',
              builder: (ctx, _) => const Scaffold(body: Text('Saved page')),
            ),
            GoRoute(
              path: 'departments',
              builder: (ctx, _) =>
                  const Scaffold(body: Text('Departments page')),
            ),
            GoRoute(
              path: 'requests',
              builder: (ctx, _) => const Scaffold(body: Text('Requests page')),
            ),
          ],
        ),
      ],
      initialLocation: '/more',
    );

    return ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.build(AppThemes.unishare),
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders 4 ListTile items with correct labels', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(4));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Departments'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
  });

  testWidgets('tapping Profile tile navigates to /more/profile', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile page'), findsOneWidget);
  });

  testWidgets('tapping Saved tile navigates to /more/saved', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved page'), findsOneWidget);
  });

  testWidgets('tapping Departments tile navigates to /more/departments', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Departments'));
    await tester.pumpAndSettle();
    expect(find.text('Departments page'), findsOneWidget);
  });

  testWidgets('tapping Requests tile navigates to /more/requests', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Requests page'), findsOneWidget);
  });
}
