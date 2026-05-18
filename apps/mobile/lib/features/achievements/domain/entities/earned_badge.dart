class EarnedBadge {
  final String badgeId;
  final DateTime earnedAt;
  final int pointsAwarded;

  const EarnedBadge({
    required this.badgeId,
    required this.earnedAt,
    required this.pointsAwarded,
  });
}
