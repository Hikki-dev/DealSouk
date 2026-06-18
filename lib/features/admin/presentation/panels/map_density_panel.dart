import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';

class MapDensityPanel extends ConsumerWidget {
  const MapDensityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.watch(adminMapDataProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.forestDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Visualizing active grocery price submissions across Dubai. Circles show submission density. Tap any marker pin to inspect store details.',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(
                25.2048,
                55.2708,
              ), // Dubai coordinates
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.dealsouk.app',
                retinaMode: RetinaMode.isHighDensity(context),
                maxZoom: 20,
              ),
              CircleLayer(
                circles: mapData.map<CircleMarker>((store) {
                  final double lat = (store['lat'] is num)
                      ? (store['lat'] as num).toDouble()
                      : 25.2048;
                  final double lng = (store['lng'] is num)
                      ? (store['lng'] as num).toDouble()
                      : 55.2708;
                  final int count =
                      store['activeSubmissionsCount'] as int? ?? 0;
                  final Color circleColor = count < 3
                      ? Colors.green.withValues(alpha: 0.4)
                      : count < 6
                      ? Colors.orange.withValues(alpha: 0.4)
                      : Colors.red.withValues(alpha: 0.4);
                  return CircleMarker(
                    point: LatLng(lat, lng),
                    radius: (count * 6.0 + 12.0).clamp(12.0, 48.0),
                    useRadiusInMeter: false,
                    color: circleColor,
                    borderColor: circleColor.withValues(alpha: 0.7),
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: mapData.map<Marker>((store) {
                  final double lat = (store['lat'] is num)
                      ? (store['lat'] as num).toDouble()
                      : 25.2048;
                  final double lng = (store['lng'] is num)
                      ? (store['lng'] as num).toDouble()
                      : 55.2708;
                  final String chain = store['chain'] as String? ?? 'Store';
                  final String branchName =
                      store['branchName'] as String? ?? '';
                  final int count =
                      store['activeSubmissionsCount'] as int? ?? 0;
                  return Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              '$chain $branchName',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Area: ${store['area'] ?? 'Dubai'}',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Approved submissions count: $count',
                                  style: GoogleFonts.nunito(
                                    color: AppTheme.forestDeep,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.forestDeep,
                        size: 32,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
