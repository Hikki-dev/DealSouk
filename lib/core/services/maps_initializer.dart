import 'maps_initializer_stub.dart'
    if (dart.library.js_util) 'maps_initializer_web.dart'
    if (dart.library.js) 'maps_initializer_web.dart'
    if (dart.library.html) 'maps_initializer_web.dart';

bool checkGoogleMapsInitialized() {
  return isGoogleMapsInitialized();
}
