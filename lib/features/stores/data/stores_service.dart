import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/domain/store_price.dart';
import 'package:dealsouk/core/network/api_client.dart';
import 'package:dealsouk/features/stores/data/store_price_seed.dart';

class StoresService {
  Future<List<Store>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5,
    String? chain,
  }) async {
    final res = await apiClient.get(
      '/stores/nearby',
      params: {'lat': lat, 'lng': lng, 'radius': radiusKm, 'chain': ?chain},
    );
    final list = res.data as List<dynamic>;
    return list.map((e) => Store.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StorePrice>> getPrices(String storeId) async {
    try {
      final res = await apiClient.get('/stores/$storeId/prices');
      final list = res.data as List<dynamic>;
      final prices = list
          .map((e) => StorePrice.fromJson(e as Map<String, dynamic>))
          .toList();
      return prices.isNotEmpty ? prices : fallbackPricesForStore(storeId);
    } catch (_) {
      return fallbackPricesForStore(storeId);
    }
  }
}

final storesService = StoresService();
