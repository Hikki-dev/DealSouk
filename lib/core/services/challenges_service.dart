import '../models/models.dart';
import 'api_client.dart';

class ChallengesService {
  Future<DailyChallenge> getToday() async {
    final res = await apiClient.get('/challenges/today');
    return DailyChallenge.fromJson(res.data as Map<String, dynamic>);
  }
}

final challengesService = ChallengesService();
