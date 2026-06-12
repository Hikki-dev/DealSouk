import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/leaderboard/domain/leaderboard_ranking.dart';

void main() {
  test('leaderboard ranking calculation sorts monthly token totals', () {
    // Protects PRD leaderboard rule: monthly ranking is based on earned token
    // totals, with deterministic ordering for tied scores.
    final ranked = rankLeaderboard(const [
      LeaderboardScore(userId: 'b', displayName: 'Basma', tokensThisMonth: 90),
      LeaderboardScore(userId: 'a', displayName: 'Aisha', tokensThisMonth: 120),
      LeaderboardScore(userId: 'c', displayName: 'Carlos', tokensThisMonth: 90),
    ]);

    expect(ranked.map((user) => user.displayName), [
      'Aisha',
      'Basma',
      'Carlos',
    ]);
    expect(ranked.map((user) => user.rank), [1, 2, 3]);
  });
}
