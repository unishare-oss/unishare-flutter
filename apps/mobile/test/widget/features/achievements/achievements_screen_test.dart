import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';

AchievementBadge _badge(String id, String name, BadgeTier tier, int order) =>
    AchievementBadge(
      id: id,
      name: name,
      description: 'desc $id',
      glyph: 'paper-plane-tilt',
      points: 15,
      tier: tier,
      category: BadgeCategory.content,
      condition: const BadgeCondition(statKey: 'postsCreated', threshold: 1),
      order: order,
      active: true,
    );

void main() {
  testWidgets('renders earned and locked sections', (tester) async {
    final catalog = [
      _badge('first_post', 'First Steps', BadgeTier.onboarding, 2),
      _badge('beloved', 'Beloved', BadgeTier.prestige, 20),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          badgeCatalogProvider.overrideWith((ref) => Stream.value(catalog)),
          earnedBadgesProvider('u1').overrideWith(
            (ref) => Stream.value([
              EarnedBadge(
                badgeId: 'first_post',
                earnedAt: DateTime(2026, 5, 18),
                pointsAwarded: 15,
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.fromId('unishare'),
          home: const AchievementsScreen(uid: 'u1'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('Beloved'), findsOneWidget);
    expect(find.text('Earned · 1'), findsOneWidget);
    expect(find.text('Locked · 1'), findsOneWidget);
  });
}
