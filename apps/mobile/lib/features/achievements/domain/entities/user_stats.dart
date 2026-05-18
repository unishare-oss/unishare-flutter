class UserStats {
  final int postsCreated;
  final int savesReceived;
  final int postsWithAtLeastOneSave;
  final int uniqueSaversCount;
  final int requestsFulfilled;
  final int requestsCreated;
  final int commentsWritten;
  final int savesGiven;
  final List<String> uniqueDepartmentsContributed;
  final bool profileCompleted;

  const UserStats({
    required this.postsCreated,
    required this.savesReceived,
    required this.postsWithAtLeastOneSave,
    required this.uniqueSaversCount,
    required this.requestsFulfilled,
    required this.requestsCreated,
    required this.commentsWritten,
    required this.savesGiven,
    required this.uniqueDepartmentsContributed,
    required this.profileCompleted,
  });

  static const empty = UserStats(
    postsCreated: 0,
    savesReceived: 0,
    postsWithAtLeastOneSave: 0,
    uniqueSaversCount: 0,
    requestsFulfilled: 0,
    requestsCreated: 0,
    commentsWritten: 0,
    savesGiven: 0,
    uniqueDepartmentsContributed: [],
    profileCompleted: false,
  );

  /// Resolves a `condition.statKey` against the in-memory stats, used by
  /// reachable-badge hints. Returns 0 for unknown keys.
  int valueFor(String statKey) {
    switch (statKey) {
      case 'postsCreated':
        return postsCreated;
      case 'savesReceived':
        return savesReceived;
      case 'postsWithAtLeastOneSave':
        return postsWithAtLeastOneSave;
      case 'uniqueSaversCount':
        return uniqueSaversCount;
      case 'requestsFulfilled':
        return requestsFulfilled;
      case 'requestsCreated':
        return requestsCreated;
      case 'commentsWritten':
        return commentsWritten;
      case 'savesGiven':
        return savesGiven;
      case 'uniqueDepartmentsCount':
        return uniqueDepartmentsContributed.length;
      case 'profileCompleted':
        return profileCompleted ? 1 : 0;
      default:
        return 0;
    }
  }
}
