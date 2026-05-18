import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/level_progress_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/profile_achievements_section.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart';

AchievementBadge _badge(String id, String name) => AchievementBadge(
  id: id,
  name: name,
  description: '',
  glyph: 'paper-plane-tilt',
  points: 15,
  tier: BadgeTier.onboarding,
  category: BadgeCategory.content,
  condition: const BadgeCondition(statKey: 'postsCreated', threshold: 1),
  order: 1,
  active: true,
);

GoRouter _router(Widget child) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/achievements/:uid',
        builder: (_, state) =>
            const Scaffold(body: Text('achievements screen')),
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<AchievementBadge> catalog,
  required List<EarnedBadge> earned,
  required UserGamification gamification,
  required LevelProgress progress,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        badgeCatalogProvider.overrideWith((ref) => Stream.value(catalog)),
        earnedBadgesProvider('u1').overrideWith((ref) => Stream.value(earned)),
        userGamificationProvider(
          'u1',
        ).overrideWith((ref) => Stream.value(gamification)),
        levelProgressProvider('u1').overrideWith((ref) => progress),
      ],
      child: MaterialApp.router(
        theme: AppTheme.fromId('unishare'),
        routerConfig: _router(const ProfileAchievementsSection(uid: 'u1')),
      ),
    ),
  );
}

void main() {
  testWidgets('shows muted placeholders when no badges displayed', (
    tester,
  ) async {
    await _pump(
      tester,
      catalog: const [],
      earned: const [],
      gamification: UserGamification.empty,
      progress: const LevelProgress(
        currentLevel: 1,
        pointsIntoLevel: 0,
        pointsToNextLevel: 30,
        fractionToNext: 0,
      ),
    );
    await tester.pump();
    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
    expect(find.text('Earn badges to display them here'), findsOneWidget);
  });

  testWidgets('shows displayed badges when set', (tester) async {
    final badge = _badge('first_post', 'First Steps');
    await _pump(
      tester,
      catalog: [badge],
      earned: [
        EarnedBadge(
          badgeId: 'first_post',
          earnedAt: DateTime(2026, 5, 18),
          pointsAwarded: 15,
        ),
      ],
      gamification: const UserGamification(
        totalPoints: 15,
        level: 1,
        selectedTitle: null,
        displayedBadges: ['first_post'],
      ),
      progress: const LevelProgress(
        currentLevel: 1,
        pointsIntoLevel: 15,
        pointsToNextLevel: 15,
        fractionToNext: 0.5,
      ),
    );
    await tester.pump();
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('15 / 30 pts to Lv 2'), findsOneWidget);
  });
}
