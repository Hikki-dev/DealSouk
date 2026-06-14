import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/data/stores_service.dart';

/// Backend-driven store list. There is no hardcoded fallback: the map and list
/// reflect exactly what the backend returns for the requested area. While the
/// first fetch is in flight [isLoading] is true so the UI can show a spinner
/// instead of an empty state.
class StoresNotifier extends Notifier<List<Store>> {
  bool isLoading = false;
  bool hasFetched = false;

  /// Non-null when the last fetch failed (backend unreachable, cold-start
  /// timeout, etc.). The UI reads this to show an error + Retry instead of a
  /// misleading "no stores" empty state. Cleared on a successful fetch.
  bool hadError = false;

  @override
  List<Store> build() => const [];

  Future<void> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 15,
  }) async {
    isLoading = true;
    try {
      final results = await storesService.getNearby(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      state = results;
      hadError = false;
    } catch (_) {
      // Backend unreachable / timed out. Don't fabricate stores — record the
      // failure so the UI can surface it (and offer Retry) rather than showing
      // a silent empty list that looks like "there are no stores".
      hadError = true;
      state = const [];
    } finally {
      isLoading = false;
      hasFetched = true;
    }
  }
}

final storesProvider = NotifierProvider<StoresNotifier, List<Store>>(
  StoresNotifier.new,
);
