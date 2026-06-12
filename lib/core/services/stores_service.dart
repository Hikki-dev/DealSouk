import '../models/models.dart';
import 'api_client.dart';

class StoresService {
  Future<List<Store>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5,
    String? chain,
  }) async {
    final res = await apiClient.get('/stores/nearby', params: {
      'lat': lat,
      'lng': lng,
      'radius': radiusKm,
      if (chain != null) 'chain': chain,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((e) => Store.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final storesService = StoresService();
