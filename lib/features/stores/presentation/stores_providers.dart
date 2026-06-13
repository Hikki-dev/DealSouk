import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/data/stores_service.dart';
import 'package:dealsouk/features/stores/data/dubai_stores_seed.dart';

class StoresNotifier extends Notifier<List<Store>> {
  @override
  List<Store> build() => dubaiStaticStores; // start with static Dubai data immediately

  Future<void> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 15,
  }) async {
    try {
      final results = await storesService.getNearby(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      // Only replace static data if the API returned real results
      if (results.isNotEmpty) {
        state = results;
      }
      // else keep the static Dubai seed data
    } catch (_) {
      // On any error (network, backend offline) keep static data
      if (state.isEmpty) {
        state = dubaiStaticStores;
      }
    }
  }
}

final storesProvider = NotifierProvider<StoresNotifier, List<Store>>(
  StoresNotifier.new,
);
