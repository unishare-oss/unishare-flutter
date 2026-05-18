import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_grid.dart';
import 'package:unishare_mobile/features/more/presentation/widgets/more_drawer_tile.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';
import 'package:unishare_mobile/shared/theme/themes.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(AppThemes.unishare),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders five tiles with the expected labels', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MoreDrawerGrid(
          onSavedTap: () {},
          onDepartmentsTap: () {},
          onRequestsTap: () {},
          onProfileTap: () {},
          onAchievementsTap: () {},
        ),
      ),
    );

    expect(find.byType(MoreDrawerTile), findsNWidgets(5));
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('DEPARTMENTS'), findsOneWidget);
    expect(find.text('REQUESTS'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
  });

  testWidgets('each tile fires its matching callback', (tester) async {
    var saved = 0, depts = 0, reqs = 0, profile = 0, achievements = 0;

    await tester.pumpWidget(
      _wrap(
        MoreDrawerGrid(
          onSavedTap: () => saved++,
          onDepartmentsTap: () => depts++,
          onRequestsTap: () => reqs++,
          onProfileTap: () => profile++,
          onAchievementsTap: () => achievements++,
        ),
      ),
    );

    await tester.tap(find.text('SAVED'));
    await tester.tap(find.text('DEPARTMENTS'));
    await tester.tap(find.text('REQUESTS'));
    await tester.tap(find.text('PROFILE'));
    await tester.tap(find.text('ACHIEVEMENTS'));
    await tester.pump();

    expect(saved, 1);
    expect(depts, 1);
    expect(reqs, 1);
    expect(profile, 1);
    expect(achievements, 1);
  });
}
