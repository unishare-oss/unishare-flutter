import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';

ThemeData _theme() => AppTheme.fromId('unishare');

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(theme: _theme(), home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  testWidgets('onboarding earned uses amber fill', (tester) async {
    await _pump(
      tester,
      const BadgeFrame(
        tier: BadgeTier.onboarding,
        locked: false,
        size: 48,
        child: Icon(Icons.star),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const Key('badge_frame_container')),
    );
    final decoration = container.decoration as BoxDecoration;
    final ac = Theme.of(
      tester.element(find.byKey(const Key('badge_frame_container'))),
    ).extension<AppColors>()!;
    expect(decoration.color, ac.amber);
  });

  testWidgets('locked uses muted fill regardless of tier', (tester) async {
    await _pump(
      tester,
      const BadgeFrame(
        tier: BadgeTier.prestige,
        locked: true,
        size: 48,
        child: Icon(Icons.lock_outline),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const Key('badge_frame_container')),
    );
    final decoration = container.decoration as BoxDecoration;
    final ac = Theme.of(
      tester.element(find.byKey(const Key('badge_frame_container'))),
    ).extension<AppColors>()!;
    expect(decoration.color, ac.muted);
  });
}
