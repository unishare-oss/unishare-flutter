class UserGamification {
  final int totalPoints;
  final int level;
  final String? selectedTitle;
  final List<String> displayedBadges;

  const UserGamification({
    required this.totalPoints,
    required this.level,
    required this.selectedTitle,
    required this.displayedBadges,
  });

  static const empty = UserGamification(
    totalPoints: 0,
    level: 1,
    selectedTitle: null,
    displayedBadges: [],
  );
}
