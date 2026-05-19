enum BadgeTier { onboarding, progression, prestige }

enum BadgeCategory { content, community, profile, recognition }

class BadgeCondition {
  final String statKey;
  final int threshold;
  const BadgeCondition({required this.statKey, required this.threshold});
}

/// Named [AchievementBadge] to avoid collision with Flutter's [Badge] widget.
class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String glyph;
  final int points;
  final BadgeTier tier;
  final BadgeCategory category;
  final BadgeCondition condition;
  final int order;
  final bool active;

  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.glyph,
    required this.points,
    required this.tier,
    required this.category,
    required this.condition,
    required this.order,
    required this.active,
  });
}
