// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js' as js;

bool isGoogleMapsInitialized() {
  try {
    return js.context.hasProperty('google') &&
        js.context['google'] != null &&
        js.context['google'].hasProperty('maps');
  } catch (_) {
    return false;
  }
}
