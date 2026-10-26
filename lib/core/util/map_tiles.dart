import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Mapbox public access token, supplied at build time via
/// `--dart-define=MAPBOX_ACCESS_TOKEN=pk...`. Never commit a value.
const _kMapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

/// Without a token the maps use OpenStreetMap's own tiles instead of showing
/// a blank grey map. Set the token to get the Mapbox street style.
const _kHasMapbox = _kMapboxToken != '';

/// Base-map raster tile layer shared by the shopper and admin maps.
TileLayer buildBaseTileLayer(BuildContext context) {
  if (!_kHasMapbox) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.dealsouk.app',
      maxZoom: 19,
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

/// Attribution required by the tile provider and OpenStreetMap terms.
Widget buildMapAttribution() {
  return RichAttributionWidget(
    attributions: [
      if (_kHasMapbox) TextSourceAttribution('Mapbox', prependCopyright: true),
      TextSourceAttribution(
        'OpenStreetMap contributors',
        prependCopyright: true,
      ),
    ],
  );
}
