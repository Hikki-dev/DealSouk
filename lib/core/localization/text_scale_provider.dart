import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The in-app "Text size" choice. It multiplies the system text size, so
/// someone who already uses a large system font gets even larger text.
enum TextSizeChoice {
  standard(1.0),
  large(1.15),
  extraLarge(1.3);

  const TextSizeChoice(this.factor);
  final double factor;
}

class TextSizeNotifier extends Notifier<TextSizeChoice> {
  static const _prefsKey = 'text_size_v1';

  @override
  TextSizeChoice build() {
    _load();
    return TextSizeChoice.standard;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final i = prefs.getInt(_prefsKey);
      if (i != null && i >= 0 && i < TextSizeChoice.values.length) {
        state = TextSizeChoice.values[i];
      }
    } catch (_) {
      // Keep the default when storage is unavailable.
    }
  }

  Future<void> set(TextSizeChoice choice) async {
    state = choice;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, choice.index);
    } catch (_) {}
  }
}

final textSizeProvider = NotifierProvider<TextSizeNotifier, TextSizeChoice>(
  TextSizeNotifier.new,
);
