import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/leaderboard/domain/leaderboard_user.dart';
import 'package:dealsouk/features/leaderboard/data/leaderboard_service.dart';

class LeaderboardNotifier extends Notifier<List<LeaderboardUser>> {
  @override
  List<LeaderboardUser> build() => [];

  Future<void> fetch() async {
    try {
      final results = await leaderboardService.getMonthly();
      state = results;
    } catch (_) {}
  }
}

final leaderboardProvider =
    NotifierProvider<LeaderboardNotifier, List<LeaderboardUser>>(
      LeaderboardNotifier.new,
    );

// FR-45: previous month's top 3 (Hall of Fame).
final hallOfFameProvider = FutureProvider<List<LeaderboardUser>>((ref) async {
  try {
    return await leaderboardService.getHallOfFame();
  } catch (_) {
    return <LeaderboardUser>[];
  }
});
