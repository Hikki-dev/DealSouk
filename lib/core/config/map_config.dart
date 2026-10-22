import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// One place that decides where every map gets its tiles.
///
/// The public CARTO Voyager URL this app used to call now answers with a
/// placeholder tile reading "API KEY REQUIRED". Production builds must pass a
/// licensed provider (MapTiler, Stadia, Mapbox, Thunderforest, ...):
///
///   --dart-define=MAP_TILE_URL=https://api.example.com/tiles/{z}/{x}/{y}.png?key=...
///   --dart-define=MAP_ATTRIBUTION="© OpenStreetMap contributors © Example"
///
/// The default is OpenStreetMap's own server, which is fine for development
/// but its usage policy forbids heavy production traffic.
class MapConfig {
  MapConfig._();

  static const String tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const String attribution = String.fromEnvironment(
    'MAP_ATTRIBUTION',
    defaultValue: '© OpenStreetMap contributors',
  );

  static const String userAgentPackageName = 'com.dealsouk.dealsouk';

  static TileLayer tileLayer(BuildContext context) => TileLayer(
    urlTemplate: tileUrl,
    userAgentPackageName: userAgentPackageName,
    retinaMode: tileUrl.contains('{r}') && RetinaMode.isHighDensity(context),
    maxZoom: 19,
  );

  /// Attribution is required by every tile provider's terms.
  static Widget attributionWidget() =>
      const SimpleAttributionWidget(source: Text(attribution));
}
