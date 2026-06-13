// ignore: unused_import
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:dealsouk/features/stores/data/stores_service.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';

/// Dubai city centre — map always defaults here
const _dubaiCenter = LatLng(25.2048, 55.2708);

/// Stores further than this are hidden when the user is in Dubai.
/// 8 km ≈ a 10–15 min drive, suitable for a grocery run.
const _maxRadiusKm = 8.0;

/// Dubai geographic bounding box — used to detect whether the
/// user is physically in Dubai (vs. testing from abroad).
const _dubaiMinLat = 24.80;
const _dubaiMaxLat = 25.45;
const _dubaiMinLng = 54.90;
const _dubaiMaxLng = 55.65;

/// Haversine distance in km between two GPS points.
double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0; // Earth radius km
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLng / 2) *
          sin(dLng / 2);
  return r * 2 * asin(sqrt(a));
}

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLocating = false;
  bool _mapReady = false;

  /// True only when the user is physically inside Dubai bounds.
  bool get _userIsInDubai {
    final p = _currentPosition;
    if (p == null) return false;
    return p.latitude >= _dubaiMinLat &&
        p.latitude <= _dubaiMaxLat &&
        p.longitude >= _dubaiMinLng &&
        p.longitude <= _dubaiMaxLng;
  }

  String _selectedChain = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _chains = [
    'All',
    'Carrefour',
    'Lulu',
    'Spinneys',
    'Waitrose',
    'Union Coop',
    'Choithrams',
    'Geant',
    'Nesto',
    'Al Maya',
    'Grandiose',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // Attempt to get location but never move the map away from Dubai
    _tryGetLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _tryGetLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final allowed = await _showLocationPrePrompt();
        if (!allowed) {
          setState(() => _isLocating = false);
          return;
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLocating = false;
      });

      // If the user IS in Dubai, pan the map to their live location
      // and fetch stores around them. If they're abroad (testing),
      // the map stays centred on Dubai and shows all static stores.
      final lat = position.latitude;
      final lng = position.longitude;
      final isInDubai =
          lat >= _dubaiMinLat &&
          lat <= _dubaiMaxLat &&
          lng >= _dubaiMinLng &&
          lng <= _dubaiMaxLng;

      if (isInDubai && _mapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(LatLng(lat, lng), 13.5);
        });
      }

      // Always try to fetch live stores from backend around Dubai
      ref
          .read(storesProvider.notifier)
          .fetchNearby(
            lat: isInDubai ? lat : 25.2048,
            lng: isInDubai ? lng : 55.2708,
            radiusKm: 40,
          );
    } catch (_) {
      setState(() => _isLocating = false);
    }
  }

  Future<bool> _showLocationPrePrompt() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.forestDeep,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Find Supermarkets Near You',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'DealSouk uses your location to show how far each Dubai supermarket is from you.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Distance from user's GPS to a store in km.
  /// Returns null when user is not in Dubai (no radius filtering).
  double? _distanceTo(Store store) {
    final p = _currentPosition;
    if (p == null || !_userIsInDubai) return null;
    return _haversineKm(p.latitude, p.longitude, store.lat, store.lng);
  }

  List<Store> _applyFilters(List<Store> stores) {
    final result = stores.where((s) {
      // Chain filter
      final chainMatch =
          _selectedChain == 'All' ||
          s.name.toLowerCase().contains(_selectedChain.toLowerCase());
      // Search filter — matches name or branch
      final searchMatch =
          _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery) ||
          s.branch.toLowerCase().contains(_searchQuery);
      if (!chainMatch || !searchMatch) return false;
      // Radius filter — only when user is physically in Dubai
      if (_userIsInDubai) {
        final dist = _distanceTo(s);
        if (dist != null && dist > _maxRadiusKm) return false;
      }
      return true;
    }).toList();

    // Sort by distance (closest first) when in Dubai, else keep seed order
    if (_userIsInDubai) {
      result.sort((a, b) {
        final da = _distanceTo(a) ?? double.maxFinite;
        final db = _distanceTo(b) ?? double.maxFinite;
        return da.compareTo(db);
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider);
    final filtered = _applyFilters(stores);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  Expanded(
                    child: Text(
                      'Store Map — Dubai',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        color: AppTheme.forestDeep,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _CircleButton(icon: Icons.tune_rounded, onTap: () {}),
                ],
              ),
            ),

            // ── Chain filter chips ────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _chains.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chain = _chains[index];
                  final isSelected = chain == _selectedChain;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedChain = chain);
                      // Snap map to first matching store if one exists
                      if (_mapReady && chain != 'All') {
                        final match = stores.firstWhere(
                          (s) => s.name.toLowerCase().contains(
                            chain.toLowerCase(),
                          ),
                          orElse: () => stores.first,
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _mapController.move(
                            LatLng(match.lat, match.lng),
                            13.0,
                          );
                        });
                      } else if (_mapReady) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _mapController.move(_dubaiCenter, 11.5);
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.forestDeep : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.forestDeep
                              : const Color(0xFFE8EEE4),
                        ),
                      ),
                      child: Text(
                        chain,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.forestDeep,
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Body list ─────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                physics: const BouncingScrollPhysics(),
                children: [
                  // ── Search bar (functional) ─────────────────────────
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFFE8EEE4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search store name or area…',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey.shade400,
                              size: 18,
                            ),
                          )
                        else
                          Icon(
                            Icons.filter_list_rounded,
                            color: AppTheme.forestDeep,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Map Card ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.forestDeep, AppTheme.maroon],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.forestDeep.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.near_me_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filtered.isEmpty
                                        ? 'No stores found'
                                        : '${filtered.length} Dubai stores',
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap a pin to see branch details',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _dubaiCenter, // Always Dubai
                                    initialZoom: 11.5,
                                    onMapReady: () {
                                      // Safe to call move() only after map is ready
                                      setState(() => _mapReady = true);
                                    },
                                    interactionOptions:
                                        const InteractionOptions(
                                          flags: InteractiveFlag.all,
                                        ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                      subdomains: const ['a', 'b', 'c', 'd'],
                                      userAgentPackageName: 'com.dealsouk.app',
                                      retinaMode: RetinaMode.isHighDensity(
                                        context,
                                      ),
                                      maxZoom: 20,
                                    ),
                                    // User location pin (only shown in Dubai)
                                    if (_userIsInDubai &&
                                        _currentPosition != null)
                                      CircleLayer(
                                        circles: [
                                          // Accuracy ring
                                          CircleMarker(
                                            point: LatLng(
                                              _currentPosition!.latitude,
                                              _currentPosition!.longitude,
                                            ),
                                            radius: _maxRadiusKm * 1000 / 50,
                                            useRadiusInMeter: false,
                                            color: AppTheme.forestDeep
                                                .withValues(alpha: 0.06),
                                            borderColor: AppTheme.forestDeep
                                                .withValues(alpha: 0.25),
                                            borderStrokeWidth: 1.5,
                                          ),
                                          // You are here dot
                                          CircleMarker(
                                            point: LatLng(
                                              _currentPosition!.latitude,
                                              _currentPosition!.longitude,
                                            ),
                                            radius: 8,
                                            color: AppTheme.forestDeep
                                                .withValues(alpha: 0.9),
                                            borderColor: Colors.white,
                                            borderStrokeWidth: 3,
                                          ),
                                        ],
                                      ),
                                    // Store markers
                                    MarkerLayer(
                                      markers: filtered.map((store) {
                                        final isStale =
                                            store.lastUpdatedHoursAgo > 48;
                                        final dist = _distanceTo(store);
                                        return Marker(
                                          point: LatLng(store.lat, store.lng),
                                          width: 40,
                                          height: 40,
                                          child: GestureDetector(
                                            onTap: () => _showStorePrices(
                                              context,
                                              store,
                                            ),
                                            child: Tooltip(
                                              message: dist != null
                                                  ? '${store.name} · ${store.branch}\n${dist.toStringAsFixed(1)} km away'
                                                  : '${store.name}\n${store.branch}',
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: _chainColor(
                                                    store.name,
                                                    isStale,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: _LogoAvatar(
                                                  name: store.name,
                                                  color: _chainColor(
                                                    store.name,
                                                    isStale,
                                                  ),
                                                  size: 40,
                                                  padding: 6,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    // OSM attribution (required)
                                    const RichAttributionWidget(
                                      attributions: [
                                        TextSourceAttribution(
                                          'OpenStreetMap contributors',
                                          prependCopyright: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Locate button (bottom-right)
                                Positioned(
                                  bottom: 44,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: _tryGetLocation,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isLocating
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppTheme.forestDeep),
                                                ),
                                              )
                                            : Icon(
                                                _currentPosition != null
                                                    ? Icons.my_location_rounded
                                                    : Icons
                                                          .location_searching_rounded,
                                                color: _currentPosition != null
                                                    ? AppTheme.forestDeep
                                                    : Colors.grey.shade500,
                                                size: 18,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                // "Reset to Dubai" button
                                Positioned(
                                  bottom: 44,
                                  left: 12,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_mapReady) {
                                        _mapController.move(_dubaiCenter, 11.5);
                                      }
                                    },
                                    child: Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.public_rounded,
                                            size: 13,
                                            color: AppTheme.forestDeep,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Dubai',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.forestDeep,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Store count + results label ──────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userIsInDubai
                                  ? 'Near You in Dubai'
                                  : 'All Dubai Stores',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            if (_userIsInDubai)
                              Text(
                                'Within ${_maxRadiusKm.toInt()} km · sorted by distance',
                                style: GoogleFonts.nunito(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.forestDeep.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${filtered.length} stores',
                            style: GoogleFonts.nunito(
                              color: AppTheme.forestDeep,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No stores match "$_searchQuery"',
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (store) => _StoreChoiceCard(
                        store: store,
                        distanceKm: _distanceTo(store),
                        onTap: () {
                          _showStorePrices(context, store);
                          // Animate map to this store (safe: only after map ready)
                          if (_mapReady) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _mapController.move(
                                LatLng(store.lat, store.lng),
                                15.0,
                              );
                            });
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a distinct color per chain for easy visual distinction on the map
  Color _chainColor(String name, bool isStale) {
    if (isStale) return Colors.grey.shade500;
    return switch (name.toLowerCase()) {
      String n when n.contains('carrefour') => const Color(0xFF0066CC),
      String n when n.contains('lulu') => const Color(0xFFE63946),
      String n when n.contains('spinneys') => const Color(0xFF2A9D8F),
      String n when n.contains('waitrose') => const Color(0xFF457B9D),
      String n when n.contains('union') => const Color(0xFFE76F51),
      String n when n.contains('choithrams') => const Color(0xFF6A4C93),
      String n when n.contains('geant') => const Color(0xFF1D3557),
      String n when n.contains('nesto') => const Color(0xFFF4A261),
      String n when n.contains('al maya') => const Color(0xFF264653),
      String n when n.contains('grandiose') => const Color(0xFF8338EC),
      _ => AppTheme.forestDeep,
    };
  }

  void _showStorePrices(BuildContext context, Store store) {
    final isStale = store.lastUpdatedHoursAgo > 48;
    final pricesFuture = storesService.getPrices(store.id);

    ref.read(navbarVisibleProvider.notifier).hide();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Logo avatar for bottom sheet header
                      _LogoAvatar(
                        name: store.name,
                        color: _chainColor(store.name, false),
                        size: 52,
                        padding: 8,
                        borderRadius: 14,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.forestDeep,
                              ),
                            ),
                            Text(
                              store.branch,
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isStale)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: Colors.grey.shade500,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stale',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: FutureBuilder(
                      future: pricesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return _StorePricesEmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'Could not load prices',
                            subtitle:
                                'Check your connection or submit a fresh price for this branch.',
                          );
                        }

                        final prices = snapshot.data ?? [];
                        if (prices.isEmpty) {
                          return const _StorePricesEmptyState(
                            icon: Icons.price_change_outlined,
                            title: 'No fresh prices yet',
                            subtitle:
                                'Be the first to share a shelf price at this branch.',
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: prices.length,
                          itemBuilder: (context, index) {
                            final price = prices[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: SizedBox(
                                width: 44,
                                height: 44,
                                child: SoukProductVisual(
                                  product: price.product,
                                  fit: BoxFit.cover,
                                  borderRadius: 12,
                                ),
                              ),
                              title: Text(
                                price.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              subtitle: Text(
                                price.verifiedWithPhoto
                                    ? '${price.updatedAtLabel} · Verified with photo'
                                    : price.updatedAtLabel,
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              trailing: SoukPrice(price.priceAed, size: 14),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/submit-price?store=${store.name}');
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.forestDeep,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Submit Price Here',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      ref.read(navbarVisibleProvider.notifier).show();
    });
  }
}

class _StorePricesEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StorePricesEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.fredoka(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.grey.shade500,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.forestDeep, size: 18),
      ),
    );
  }
}

class _StoreChoiceCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  /// Distance from user's current position in km — null when user is not in Dubai.
  final double? distanceKm;

  const _StoreChoiceCard({
    required this.store,
    required this.onTap,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final isStale = store.lastUpdatedHoursAgo > 48;
    final chainColor = _chainColorStatic(store.name);

    return Opacity(
      opacity: isStale ? 0.7 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isStale ? Colors.grey.shade300 : const Color(0xFFE8EEE4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo avatar for list card
              _LogoAvatar(
                name: store.name,
                color: isStale ? Colors.grey.shade400 : chainColor,
                size: 44,
                padding: 6,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        color: AppTheme.textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 11,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            store.branch,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (distanceKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: distanceKm! <= 3
                            ? const Color(0xFF2A9D8F).withValues(alpha: 0.12)
                            : distanceKm! <= 6
                            ? AppTheme.forestDeep.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_rounded,
                            size: 9,
                            color: distanceKm! <= 3
                                ? const Color(0xFF2A9D8F)
                                : distanceKm! <= 6
                                ? AppTheme.forestDeep
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${distanceKm!.toStringAsFixed(1)} km',
                            style: GoogleFonts.nunito(
                              color: distanceKm! <= 3
                                  ? const Color(0xFF2A9D8F)
                                  : distanceKm! <= 6
                                  ? AppTheme.forestDeep
                                  : Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: chainColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'View Prices',
                        style: GoogleFonts.nunito(
                          color: chainColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  static Color _chainColorStatic(String name) {
    return switch (name.toLowerCase()) {
      String n when n.contains('carrefour') => const Color(0xFF0066CC),
      String n when n.contains('lulu') => const Color(0xFFE63946),
      String n when n.contains('spinneys') => const Color(0xFF2A9D8F),
      String n when n.contains('waitrose') => const Color(0xFF457B9D),
      String n when n.contains('union') => const Color(0xFFE76F51),
      String n when n.contains('choithrams') => const Color(0xFF6A4C93),
      String n when n.contains('geant') => const Color(0xFF1D3557),
      String n when n.contains('nesto') => const Color(0xFFF4A261),
      String n when n.contains('al maya') => const Color(0xFF264653),
      String n when n.contains('grandiose') => const Color(0xFF8338EC),
      _ => AppTheme.forestDeep,
    };
  }
}

// ─── Shared logo URL resolver ────────────────────────────────────────────────

/// Maps a chain name to its publicly available logo URL.
/// Sourced from Clearbit's logo CDN — no API key required for standard logos.
/// Falls back gracefully inside [_LogoAvatar] if the URL fails to load.
String? _chainLogoUrl(String name) {
  final n = name.toLowerCase();
  if (n.contains('carrefour')) {
    return 'https://logo.clearbit.com/carrefour.com';
  } else if (n.contains('lulu')) {
    return 'https://logo.clearbit.com/luluhypermarket.com';
  } else if (n.contains('spinneys')) {
    return 'https://logo.clearbit.com/spinneys.com';
  } else if (n.contains('waitrose')) {
    return 'https://logo.clearbit.com/waitrose.com';
  } else if (n.contains('union')) {
    return 'https://logo.clearbit.com/unioncoop.ae';
  } else if (n.contains('choithrams')) {
    return 'https://logo.clearbit.com/choithrams.com';
  } else if (n.contains('geant')) {
    return 'https://logo.clearbit.com/geant.com';
  } else if (n.contains('nesto')) {
    return 'https://logo.clearbit.com/nestogroup.com';
  } else if (n.contains('al maya')) {
    return 'https://logo.clearbit.com/almaya.ae';
  } else if (n.contains('grandiose')) {
    return 'https://logo.clearbit.com/grandiose.ae';
  }
  return null;
}

// ─── Logo Avatar Widget ───────────────────────────────────────────────────────

/// Circular (or rounded-square) avatar showing a chain's real logo.
/// Shows the letter initial as a fallback while loading or on error.
class _LogoAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  /// Inner padding around the logo image.
  final double padding;

  /// Corner radius. Defaults to size/2 (full circle). Pass a fixed value for
  /// rounded-square cards.
  final double? borderRadius;

  const _LogoAvatar({
    required this.name,
    required this.color,
    required this.size,
    this.padding = 6,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = _chainLogoUrl(name);
    final radius = borderRadius ?? size / 2;
    final bgColor = logoUrl != null ? Colors.white : color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildContent(logoUrl, radius),
    );
  }

  Widget _buildContent(String? logoUrl, double radius) {
    if (logoUrl == null) return _fallback(radius);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius - 1.5),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return _fallback(radius);
          },
          errorBuilder: (ctx, error, stack) => _fallback(radius),
        ),
      ),
    );
  }

  Widget _fallback(double radius) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius - 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
