import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// G3 / US-10: a persisted quick-access list of saved product IDs, distinct
/// from the Grocery Cart. Survives sessions via SharedPreferences (single list
/// in v1.0; multiple lists are out of scope per the PRD note on US-10).
class SavedProductsNotifier extends Notifier<Set<String>> {
  static const _key = 'saved_products_v1';

  @override
  Set<String> build() {
    _load();
    return <String>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  bool contains(String id) => state.contains(id);

  /// Adds the id if absent, removes it if present. Persists either way.
  Future<void> toggle(String id) async {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
    await _persist();
  }

  Future<void> remove(String id) async {
    if (!state.contains(id)) return;
    state = {...state}..remove(id);
    await _persist();
  }
}

final savedProductsProvider =
    NotifierProvider<SavedProductsNotifier, Set<String>>(
      SavedProductsNotifier.new,
    );
