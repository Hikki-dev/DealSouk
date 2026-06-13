import 'package:dealsouk/features/leaderboard/domain/leaderboard_user.dart';
import 'package:dealsouk/core/network/api_client.dart';

class LeaderboardService {
  Future<List<LeaderboardUser>> getMonthly() async {
    final res = await apiClient.get('/leaderboard/monthly');
    final data = res.data as Map<String, dynamic>;
    final top10 = (data['top10'] as List<dynamic>)
        .map((e) => LeaderboardUser.fromJson(e as Map<String, dynamic>))
        .toList();
    final currentUser = data['currentUser'] as Map<String, dynamic>?;
    if (currentUser != null) {
      final alreadyIn = top10.any(
        (u) => u.rank == (currentUser['rank'] as int?),
      );
      if (!alreadyIn) {
        top10.add(LeaderboardUser.fromJson(currentUser, isCurrentUser: true));
      } else {
        return top10.map((u) {
          if (u.rank == (currentUser['rank'] as int?)) {
            return LeaderboardUser(
              rank: u.rank,
              name: u.name,
              tokens: u.tokens,
              isCurrentUser: true,
              streak: u.streak,
            );
          }
          return u;
        }).toList();
      }
    }
    return top10;
  }

  // FR-45: previous calendar month's top 3 sourcers (Hall of Fame).
  Future<List<LeaderboardUser>> getHallOfFame() async {
    final res = await apiClient.get('/leaderboard/monthly');
    final data = res.data as Map<String, dynamic>;
    final hof = (data['hallOfFame'] as List<dynamic>? ?? [])
        .map((e) => LeaderboardUser.fromJson(e as Map<String, dynamic>))
        .toList();
    return hof;
  }
}

final leaderboardService = LeaderboardService();
