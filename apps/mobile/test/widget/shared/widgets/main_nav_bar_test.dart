import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/core/router/router.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';
import 'package:unishare_mobile/shared/widgets/main_nav_bar.dart';

Widget _buildSubject({
  int activeIndex = 0,
  ValueChanged<int>? onTap,
  int? notificationsBadgeCount,
}) {
  return MaterialApp(
    theme: AppTheme.build(AppThemes.unishare),
    home: Scaffold(
      bottomNavigationBar: MainNavBar(
        activeIndex: activeIndex,
        onTap: onTap ?? (_) {},
        notificationsBadgeCount: notificationsBadgeCount,
      ),
    ),
  );
}

void main() {
  group('MainNavBar', () {
    testWidgets('renders 4 Semantics button items', (tester) async {
      await tester.pumpWidget(_buildSubject());
      final buttons = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.button == true)
          .toList();
      expect(buttons.length, 4);
    });

    testWidgets('active tab at index 0 shows filled home icon', (tester) async {
      await tester.pumpWidget(_buildSubject(activeIndex: 0));
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('active tab at index 1 shows filled article icon', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(activeIndex: 1));
      expect(find.byIcon(Icons.article_rounded), findsOneWidget);
    });

    testWidgets('active tab at index 2 shows filled notifications icon', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(activeIndex: 2));
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    });

    testWidgets('inactive tabs show outlined icons', (tester) async {
      await tester.pumpWidget(_buildSubject(activeIndex: 0));
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('active tab icon uses amber color', (tester) async {
      await tester.pumpWidget(_buildSubject(activeIndex: 0));
      final icon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
      expect(icon.color, AppThemes.unishare.amber);
    });

    testWidgets('inactive tab icon uses textMuted color', (tester) async {
      await tester.pumpWidget(_buildSubject(activeIndex: 0));
      final icon = tester.widget<Icon>(find.byIcon(Icons.article_outlined));
      expect(icon.color, AppThemes.unishare.textMuted);
    });

    testWidgets('onTap fires with correct index for each tab', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(_buildSubject(onTap: tapped.add));
      final tabLabels = ['Feed', 'Posts', 'Notifications', 'More'];
      for (int i = 0; i < NavTab.values.length; i++) {
        tapped.clear();
        await tester.tap(find.bySemanticsLabel(tabLabels[i]));
        await tester.pump();
        expect(tapped, [i], reason: '"${tabLabels[i]}" should fire onTap($i)');
      }
    });

    testWidgets('badge absent when notificationsBadgeCount is null', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('badge absent when notificationsBadgeCount is 0', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(notificationsBadgeCount: 0));
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('badge present when notificationsBadgeCount > 0', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(notificationsBadgeCount: 3));
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('each tab item has sentence-case Semantics label', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      final labels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.button == true)
          .map((s) => s.properties.label)
          .toSet();
      expect(labels, containsAll(['Feed', 'Posts', 'Notifications', 'More']));
    });
  });
}
