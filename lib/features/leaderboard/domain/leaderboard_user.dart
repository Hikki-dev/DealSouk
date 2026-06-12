class LeaderboardUser {
  final int rank;
  final String name;
  final int tokens;
  final bool isCurrentUser;
  final int streak;

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.tokens,
    required this.isCurrentUser,
    this.streak = 0,
  });

  factory LeaderboardUser.fromJson(
    Map<String, dynamic> json, {
    bool isCurrentUser = false,
  }) {
    return LeaderboardUser(
      rank: json['rank'] as int,
      name: json['displayName'] as String,
      tokens: (json['tokensThisMonth'] as int?) ?? 0,
      isCurrentUser: isCurrentUser,
    );
  }
}
