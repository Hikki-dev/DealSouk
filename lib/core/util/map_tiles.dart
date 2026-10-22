import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Mapbox public access token, supplied at build time via
/// `--dart-define=MAPBOX_ACCESS_TOKEN=pk...`. Never commit a value.
const _kMapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

/// Base-map raster tile layer shared by the shopper and admin maps.
TileLayer buildBaseTileLayer(BuildContext context) {
  if (_kMapboxToken.isEmpty) {
    debugPrint(
      'MAPBOX_ACCESS_TOKEN is not set; map tiles will fail to load. '
      'Pass --dart-define=MAPBOX_ACCESS_TOKEN=<token>.',
    );
  }
  return TileLayer(
    // `{r}` becomes `@2x` when retinaMode is on.
    urlTemplate:
        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}{r}?access_token=$_kMapboxToken',
    userAgentPackageName: 'com.dealsouk.app',
    retinaMode: RetinaMode.isHighDensity(context),
    maxZoom: 22,
  );
}

/// Attribution required by Mapbox and OpenStreetMap terms.
Widget buildMapAttribution() {
  return RichAttributionWidget(
    attributions: [
      TextSourceAttribution('Mapbox', prependCopyright: true),
      TextSourceAttribution(
        'OpenStreetMap contributors',
        prependCopyright: true,
      ),
    ],
  );
}
