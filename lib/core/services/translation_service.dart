import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/core/network/api_client.dart';

/// Translates arbitrary user-generated content via the backend proxy.
/// Static UI strings are handled by .arb / AppLocalizations — this service
/// only handles dynamic strings that come from the database (product names,
/// store names, request descriptions, etc.).
class TranslationService {
  final _cache = <String, String>{};

  Future<String> translate(String text, String targetLocale) async {
    if (text.isEmpty) return text;
    final key = '$targetLocale:$text';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final response = await apiClient.post(
        '/translate',
        data: {'text': text, 'target': targetLocale},
      );
      final translated =
          (response.data as Map<String, dynamic>?)?['translatedText']
              as String? ??
          text;
      _cache[key] = translated;
      return translated;
    } catch (_) {
      return text;
    }
  }
}

final translationServiceProvider = Provider((_) => TranslationService());
