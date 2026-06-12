class LeaderboardScore {
  final String userId;
  final String displayName;
  final int tokensThisMonth;

  const LeaderboardScore({
    required this.userId,
    required this.displayName,
    required this.tokensThisMonth,
  });
}

class RankedLeaderboardUser {
  final int rank;
  final String userId;
  final String displayName;
  final int tokensThisMonth;

  const RankedLeaderboardUser({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.tokensThisMonth,
  });
}

List<RankedLeaderboardUser> rankLeaderboard(List<LeaderboardScore> scores) {
  final sorted = [...scores]
    ..sort((a, b) {
      final tokenCompare = b.tokensThisMonth.compareTo(a.tokensThisMonth);
      if (tokenCompare != 0) return tokenCompare;
      return a.displayName.compareTo(b.displayName);
    });

  return [
    for (var i = 0; i < sorted.length; i++)
      RankedLeaderboardUser(
        rank: i + 1,
        userId: sorted[i].userId,
        displayName: sorted[i].displayName,
        tokensThisMonth: sorted[i].tokensThisMonth,
      ),
  ];
}
