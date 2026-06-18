// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:dealsouk/l10n/app_localizations.dart';
import 'package:dealsouk/core/util/geo_utils.dart';

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
  double _customMaxRadiusKm = 8.0;
  String _sortBy = 'distance'; // 'distance', 'name', 'last_updated'

  /// True while the first backend store fetch is in flight, so the UI shows a
  /// loading state instead of a misleading "No stores found" during the
  /// (free-tier) cold-start wait.
  bool _loadingStores = true;

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
    'Al Madina',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // Load Dubai stores from the backend immediately, independent of location
    // permission (there is no hardcoded fallback). _tryGetLocation refines the
    // view only if the user grants location and is physically in Dubai.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadStores();
      final pos = ref.read(userLocationProvider);
      if (pos != null) {
        setState(() {
          _currentPosition = pos;
        });
        if (_mapReady) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 13.5);
        }
      } else {
        _tryGetLocation();
      }
    });
  }

  /// Fetch the Dubai-area stores and toggle the loading flag. Reused by the
  /// initial load and the Retry button shown when a fetch fails.
  Future<void> _reloadStores() async {
    if (mounted) setState(() => _loadingStores = true);
    await ref
        .read(storesProvider.notifier)
        .fetchNearby(
          lat: _dubaiCenter.latitude,
          lng: _dubaiCenter.longitude,
          radiusKm: 40,
        );
    if (mounted) setState(() => _loadingStores = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _tryGetLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!mounted) return;
        if (!serviceEnabled) {
          setState(() => _isLocating = false);
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        final allowed = await _showLocationPrePrompt();
        if (!mounted) return;
        if (!allowed) {
          setState(() => _isLocating = false);
          return;
        }
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
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
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLocating = false;
      });
      ref.read(userLocationProvider.notifier).state = position;

      // If the user IS in Dubai, pan the map to their live location and refetch
      // stores around them. If they're abroad (testing), the Dubai-center fetch
      // started in initState already populated the list — no refetch needed.
      final lat = position.latitude;
      final lng = position.longitude;
      final isInDubai =
          lat >= _dubaiMinLat &&
          lat <= _dubaiMaxLat &&
          lng >= _dubaiMinLng &&
          lng <= _dubaiMaxLng;

      if (_mapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(LatLng(lat, lng), 13.5);
        });
      }

      if (isInDubai) {
        ref
            .read(storesProvider.notifier)
            .fetchNearby(lat: lat, lng: lng, radiusKm: 40);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLocating = false);
    }
  }

  Future<bool> _showLocationPrePrompt() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final l = AppLocalizations.of(context)!;
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
                      l.storeLocationPromptTitle,
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
                l.storeLocationPromptBody,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    l.storeLocationPromptSkip,
                    style: const TextStyle(color: Colors.grey),
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
                  child: Text(
                    l.storeLocationPromptAllow,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Distance from user's GPS to a store in km.
  double? _distanceTo(Store store) {
    final p = _currentPosition;
    if (p == null) return null;
    return haversineKm(p.latitude, p.longitude, store.lat, store.lng);
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
        if (dist != null && dist > _customMaxRadiusKm) return false;
      }
      return true;
    }).toList();

    // Sort according to selection
    if (_sortBy == 'distance' && _currentPosition != null) {
      result.sort((a, b) {
        final da = _distanceTo(a) ?? double.maxFinite;
        final db = _distanceTo(b) ?? double.maxFinite;
        return da.compareTo(db);
      });
    } else if (_sortBy == 'name' ||
        (_sortBy == 'distance' && _currentPosition == null)) {
      result.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'last_updated') {
      result.sort(
        (a, b) => a.lastUpdatedHoursAgo.compareTo(b.lastUpdatedHoursAgo),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                    mirrorInRtl: true,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  Expanded(
                    child: Text(
                      l.storeMapTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        color: AppTheme.forestDeep,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.tune_rounded,
                    onTap: () => _showFilterBottomSheet(context),
                  ),
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
                              hintText: l.storeSearchHint,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        // Clear button only. Filtering lives in the single
                        // top-right control (the tune button) so there's just
                        // one obvious place to filter, not two that do the same
                        // thing.
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
                                    (_loadingStores && filtered.isEmpty)
                                        ? l.storeLoadingStores
                                        : filtered.isEmpty
                                        ? l.storeNoStoresFound
                                        : l.storeDubaiStoresCount(
                                            filtered.length,
                                          ),
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l.storeTapPinHint,
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
                                    // User location pin (shown when position is available)
                                    if (_currentPosition != null)
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
                                          width: 52,
                                          height: 52,
                                          child: GestureDetector(
                                            onTap: () => _showStorePrices(
                                              context,
                                              store,
                                            ),
                                            child: Tooltip(
                                              message: dist != null
                                                  ? l.storeMarkerTooltipWithDistance(
                                                      store.name,
                                                      store.branch,
                                                      dist.toStringAsFixed(1),
                                                    )
                                                  : l.storeMarkerTooltip(
                                                      store.name,
                                                      store.branch,
                                                    ),
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
                                                    strokeAlign: BorderSide
                                                        .strokeAlignOutside,
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
                                                  size: 52,
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
                                            l.storeResetDubai,
                                            style: const TextStyle(
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
                                  ? l.storeNearYouTitle
                                  : l.storeAllStoresTitle,
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            if (_userIsInDubai)
                              Text(
                                l.storeWithinRadiusSorted(_maxRadiusKm.toInt()),
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
                            l.storeStoresCount(filtered.length),
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

                  if (_loadingStores && filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.forestDeep,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l.storeLoadingStores,
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (ref.read(storesProvider.notifier).hadError &&
                      _searchQuery.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.storeLoadErrorTitle,
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.storeLoadErrorSubtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _loadingStores ? null : _reloadStores,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(l.storeRetryButton),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.forestDeep,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
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
                              l.storeNoStoresMatch(_searchQuery),
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
      String n when n.contains('al madina') || n.contains('madina') =>
        const Color(0xFF0D9488),
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
        final l = AppLocalizations.of(context)!;
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
                                l.storeStaleBadge,
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
                            title: l.storePricesLoadErrorTitle,
                            subtitle: l.storePricesLoadErrorSubtitle,
                          );
                        }

                        final prices = snapshot.data ?? [];
                        if (prices.isEmpty) {
                          return _StorePricesEmptyState(
                            icon: Icons.price_change_outlined,
                            title: l.storeNoPricesTitle,
                            subtitle: l.storeNoPricesSubtitle,
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
                                    ? l.storePriceVerifiedWithPhoto(
                                        price.updatedAtLabel,
                                      )
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.storeSubmitPriceHere,
                            style: const TextStyle(
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

  void _showFilterBottomSheet(BuildContext context) {
    ref.read(navbarVisibleProvider.notifier).hide();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Filter Stores',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Maximum Distance: ${_customMaxRadiusKm.toStringAsFixed(0)} km',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Slider(
                      value: _customMaxRadiusKm,
                      min: 2.0,
                      max: 50.0,
                      divisions: 24,
                      label: '${_customMaxRadiusKm.toStringAsFixed(0)} km',
                      activeColor: AppTheme.forestDeep,
                      onChanged: (val) {
                        setBottomSheetState(() {
                          _customMaxRadiusKm = val;
                        });
                        setState(() {});
                      },
                    ),
                    if (!_userIsInDubai) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          '(Distance filter applies only when inside Dubai with GPS enabled)',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Sort Stores By',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Closest First'),
                      value: 'distance',
                      groupValue: _sortBy,
                      activeColor: AppTheme.forestDeep,
                      onChanged: _userIsInDubai
                          ? (val) {
                              if (val != null) {
                                setBottomSheetState(() => _sortBy = val);
                                setState(() {});
                              }
                            }
                          : null,
                      subtitle: !_userIsInDubai
                          ? const Text('Requires GPS location')
                          : null,
                    ),
                    RadioListTile<String>(
                      title: const Text('Alphabetical (A-Z)'),
                      value: 'name',
                      groupValue: _sortBy,
                      activeColor: AppTheme.forestDeep,
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() => _sortBy = val);
                          setState(() {});
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Recently Updated'),
                      value: 'last_updated',
                      groupValue: _sortBy,
                      activeColor: AppTheme.forestDeep,
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() => _sortBy = val);
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
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

  /// Set for directional glyphs (back arrows) that must flip in RTL.
  final bool mirrorInRtl;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.mirrorInRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
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
        child: mirrorInRtl
            ? DirectionalIcon(icon, color: AppTheme.forestDeep, size: 18)
            : Icon(icon, color: AppTheme.forestDeep, size: 18),
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
    final l = AppLocalizations.of(context)!;
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
                            l.storeDistanceKm(distanceKm!.toStringAsFixed(1)),
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
                        l.storeViewPrices,
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
              DirectionalIcon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
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
      String n when n.contains('al madina') || n.contains('madina') =>
        const Color(0xFF0D9488),
      _ => AppTheme.forestDeep,
    };
  }
}

// ─── Shared logo URL resolver ────────────────────────────────────────────────

/// Maps a chain name to its publicly available logo URL.
/// Sourced from Clearbit's logo CDN — no API key required for standard logos.
/// Maps a store name to its bundled brand-logo asset path.
/// Resolves a store name to its brand logo, served through our own backend
/// (`/logos/:slug`). The backend proxies the chain's logo mark and adds CORS +
/// cache headers, so it renders on Flutter Web (CanvasKit) too — a direct
/// third-party favicon URL fails there for lack of CORS. Cached after first
/// load, so repeat views are instant. Returns null for unknown chains;
/// [_LogoAvatar] then shows a colored letter circle (also used while loading).

// Logos are public assets — always served from the real backend even in debug.
// This matters on real iOS/Android devices where localhost:3000 is unreachable.
const _kLogoBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://dealsouk.onrender.com',
);

/// Resolves a chain name to its bundled asset slug (e.g. 'carrefour'), or null
/// for unknown chains. The slug maps to `assets/logos/<slug>.png` and to the
/// backend proxy route `/logos/<slug>`.
String? _chainSlug(String name) {
  final n = name.toLowerCase();
  if (n.contains('carrefour')) return 'carrefour';
  if (n.contains('lulu')) return 'lulu';
  if (n.contains('spinneys')) return 'spinneys';
  if (n.contains('waitrose')) return 'waitrose';
  if (n.contains('union')) return 'union_coop';
  if (n.contains('choithrams')) return 'choithrams';
  if (n.contains('geant')) return 'geant';
  if (n.contains('nesto')) return 'nesto';
  if (n.contains('al maya')) return 'al_maya';
  if (n.contains('grandiose')) return 'grandiose';
  if (n.contains('al madina') || n.contains('madina')) return 'al_madina';
  return null;
}

/// Network fallback for a chain logo when no bundled asset is present.
/// Served through our own backend (`/logos/:slug`) so it carries CORS + cache
/// headers and renders on Flutter Web too. Returns null for unknown chains.
String? _chainLogoUrl(String name) {
  final slug = _chainSlug(name);
  if (slug == null) return null;
  return '$_kLogoBaseUrl/logos/$slug';
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
    final slug = _chainSlug(name);
    final radius = borderRadius ?? size / 2;
    final bgColor = slug != null ? Colors.white : color;

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
      child: _buildContent(slug, radius),
    );
  }

  /// Logo resolution order:
  ///   1. Bundled asset `assets/logos/<slug>.png` (instant, offline, no flicker)
  ///   2. Backend proxy `/logos/<slug>` (if the asset isn't present)
  ///   3. Polished brand-colored initial (always renders)
  Widget _buildContent(String? slug, double radius) {
    if (slug == null) return _fallback(radius);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius - 1.5),
      child: Image.asset(
        'assets/logos/$slug.png',
        fit: BoxFit.contain,
        // Pad the bundled mark so it sits cleanly inside the circle.
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return Container(
              color: Colors.white,
              padding: EdgeInsets.all(padding),
              child: child,
            );
          }
          return _fallback(radius);
        },
        // No bundled asset yet → try the backend proxy, then the initial.
        errorBuilder: (ctx, assetErr, assetStack) => _networkOrFallback(radius),
      ),
    );
  }

  Widget _networkOrFallback(double radius) {
    final url = _chainLogoUrl(name);
    if (url == null) return _fallback(radius);
    return Image.network(
      url,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(padding),
            child: child,
          );
        }
        return _fallback(radius);
      },
      errorBuilder: (ctx, error, stack) => _fallback(radius),
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
