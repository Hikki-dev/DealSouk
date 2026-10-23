// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:dealsouk/core/util/map_tiles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:dealsouk/features/stores/data/stores_service.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/offline/connectivity_service.dart';
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
              backgroundColor: Colors.white,
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
                      style: AppFonts.display(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                l.storeLocationPromptBody,
                style: AppFonts.body(fontSize: 16, height: 1.4),
              ),
              actionsOverflowDirection: VerticalDirection.down,
              actions: [
                DsButton(
                  label: l.storeLocationPromptAllow,
                  onPressed: () => Navigator.pop(context, true),
                ),
                DsButton(
                  label: l.storeLocationPromptSkip,
                  style: DsButtonStyle.ghost,
                  onPressed: () => Navigator.pop(context, false),
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

  void _focusChain(String chain, List<Store> stores) {
    setState(() => _selectedChain = chain);
    if (!_mapReady) return;
    LatLng target = _dubaiCenter;
    double zoom = 11.5;
    if (chain != 'All') {
      final match = stores.where(
        (s) => s.name.toLowerCase().contains(chain.toLowerCase()),
      );
      if (match.isNotEmpty) {
        target = LatLng(match.first.lat, match.first.lng);
        zoom = 13.0;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(target, zoom);
    });
  }

  void _selectStore(Store store) {
    _showStorePrices(context, store);
    if (_mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(LatLng(store.lat, store.lng), 15.0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider);
    final online = ref.watch(isOnlineProvider);
    final filtered = _applyFilters(stores);
    final l = AppLocalizations.of(context)!;

    final controls = _buildControls(l, stores);
    final map = _buildMap(l, filtered);

    final Widget body;
    if (context.isCompact) {
      body = Column(
        children: [
          controls,
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: map),
                DraggableScrollableSheet(
                  initialChildSize: 0.42,
                  minChildSize: 0.16,
                  maxChildSize: 0.92,
                  snap: true,
                  builder: (context, scroll) => DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 12),
                      ],
                    ),
                    child: _buildList(l, filtered, online, scroll),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      final panelWidth = context.isExpanded ? 400.0 : 340.0;
      body = Row(
        children: [
          SizedBox(
            width: panelWidth,
            child: Column(
              children: [
                controls,
                Expanded(child: _buildList(l, filtered, online, null)),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.line),
          Expanded(child: map),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(bottom: false, child: body),
    );
  }

  // ── Search, filter button and chain chips ────────────────────────────────

  Widget _buildControls(AppLocalizations l, List<Store> stores) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsetsDirectional.only(start: 14, end: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.line, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.ink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Semantics(
                          textField: true,
                          label: l.storeSearchHint,
                          child: TextField(
                            controller: _searchController,
                            style: AppFonts.body(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: l.storeSearchHint,
                              hintStyle: AppFonts.body(
                                fontSize: 16,
                                color: AppTheme.textLight,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          tooltip: l.welcomeCancel,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DsIconButton(
                icon: Icons.tune_rounded,
                semanticLabel: l.storeFilterTitle,
                onPressed: () => _showFilterBottomSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DsChipRow(
            chips: [
              for (final chain in _chains)
                DsChip(
                  label: chain == 'All' ? l.storeChainAll : chain,
                  selected: chain == _selectedChain,
                  onTap: () => _focusChain(chain, stores),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Map ───────────────────────────────────────────────────────────────────

  Widget _buildMap(AppLocalizations l, List<Store> filtered) {
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _dubaiCenter,
              initialZoom: 11.5,
              onMapReady: () => setState(() => _mapReady = true),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              buildBaseTileLayer(context),
              if (_currentPosition != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      radius: _maxRadiusKm * 1000 / 50,
                      useRadiusInMeter: false,
                      color: AppTheme.forestDeep.withValues(alpha: 0.06),
                      borderColor: AppTheme.forestDeep.withValues(alpha: 0.25),
                      borderStrokeWidth: 1.5,
                    ),
                    CircleMarker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      radius: 8,
                      color: const Color(0xFF1A73E8),
                      borderColor: Colors.white,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final store in filtered)
                    Marker(
                      point: LatLng(store.lat, store.lng),
                      width: 56,
                      height: 66,
                      alignment: Alignment.topCenter,
                      child: _StorePin(
                        store: store,
                        label: _distanceTo(store) != null
                            ? l.storeMarkerTooltipWithDistance(
                                store.name,
                                store.branch,
                                _distanceTo(store)!.toStringAsFixed(1),
                              )
                            : l.storeMarkerTooltip(store.name, store.branch),
                        onTap: () => _selectStore(store),
                      ),
                    ),
                ],
              ),
              buildMapAttribution(),
            ],
          ),
        ),
        // Locate me (48px target).
        PositionedDirectional(
          top: 12,
          end: 12,
          child: Semantics(
            button: true,
            label: l.storeResetDubai,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _tryGetLocation,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: _isLocating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(
                            _currentPosition != null
                                ? Icons.my_location_rounded
                                : Icons.location_searching_rounded,
                            color: AppTheme.forestDeep,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 12,
          start: 12,
          child: Material(
            color: Colors.white,
            elevation: 3,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                if (_mapReady) _mapController.move(_dubaiCenter, 11.5);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.public_rounded,
                        size: 18,
                        color: AppTheme.forestDeep,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.storeResetDubai,
                        style: AppFonts.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.forestDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(
    AppLocalizations l,
    List<Store> filtered,
    bool online,
    ScrollController? scroll,
  ) {
    final hadError = ref.read(storesProvider.notifier).hadError;
    final Widget content;
    if (_loadingStores && filtered.isEmpty) {
      content = Column(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: DsListRowSkeleton(),
            ),
        ],
      );
    } else if (hadError && _searchQuery.isEmpty) {
      content = DsEmptyState(
        icon: Icons.cloud_off_rounded,
        tone: DsEmptyTone.error,
        title: l.storeLoadErrorTitle,
        message: l.storeLoadErrorSubtitle,
        primaryLabel: l.storeRetryButton,
        onPrimary: _loadingStores ? null : _reloadStores,
      );
    } else if (filtered.isEmpty) {
      content = DsEmptyState(
        icon: Icons.search_off_rounded,
        title: l.storeNoStoresFound,
        message: _searchQuery.isEmpty
            ? null
            : l.storeNoStoresMatch(_searchQuery),
      );
    } else {
      content = Column(
        children: [
          for (final store in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StoreRow(
                store: store,
                distanceKm: _distanceTo(store),
                onTap: () => _selectStore(store),
              ),
            ),
        ],
      );
    }

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      children: [
        if (scroll != null)
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        if (!online)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DsBanner(l.offlineBanner, tone: DsBannerTone.offline),
          ),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  _userIsInDubai ? l.storeNearYouTitle : l.storeAllStoresTitle,
                  style: AppFonts.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ),
            Text(
              l.storeStoresCount(filtered.length),
              style: AppFonts.body(fontSize: 15, color: AppTheme.textLight),
            ),
          ],
        ),
        if (_userIsInDubai)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l.storeWithinRadiusSorted(_customMaxRadiusKm.toInt()),
              style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
            ),
          ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  // ── Store prices sheet ────────────────────────────────────────────────────

  void _showStorePrices(BuildContext context, Store store) {
    final isStale = store.lastUpdatedHoursAgo > 48;
    final pricesFuture = storesService.getPrices(store.id);

    ref.read(navbarVisibleProvider.notifier).hide();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.background,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.line,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      DsStoreLogo(store.name, size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: AppFonts.display(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            Text(
                              store.branch,
                              style: AppFonts.body(
                                color: AppTheme.textLight,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isStale) DsTag(l.storeStaleBadge, tone: DsTone.bad),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: FutureBuilder(
                      future: pricesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return ListView(
                            children: const [
                              DsListRowSkeleton(),
                              SizedBox(height: 10),
                              DsListRowSkeleton(),
                              SizedBox(height: 10),
                              DsListRowSkeleton(),
                            ],
                          );
                        }
                        if (snapshot.hasError) {
                          return DsEmptyState(
                            icon: Icons.wifi_off_rounded,
                            tone: DsEmptyTone.error,
                            title: l.storePricesLoadErrorTitle,
                            message: l.storePricesLoadErrorSubtitle,
                          );
                        }
                        final prices = snapshot.data ?? [];
                        if (prices.isEmpty) {
                          return DsEmptyState(
                            icon: Icons.price_change_outlined,
                            title: l.storeNoPricesTitle,
                            message: l.storeNoPricesSubtitle,
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: prices.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final price = prices[index];
                            return DsCard(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: SoukProductVisual(
                                      product: price.product,
                                      fit: BoxFit.contain,
                                      borderRadius: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          price.product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.body(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (price.verifiedWithPhoto)
                                              DsTag(
                                                l.homeVerifiedWithPhoto,
                                                tone: DsTone.teal,
                                              ),
                                            Text(
                                              price.updatedAtLabel,
                                              style: AppFonts.body(
                                                fontSize: 13,
                                                color: AppTheme.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DsPrice(price.priceAed, size: 22),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  DsButton(
                    label: l.storeSubmitPriceHere,
                    icon: Icons.add_a_photo_outlined,
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(
                        '/submit-price?store=${Uri.encodeComponent(store.name)}',
                      );
                    },
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

  // ── Filter sheet ──────────────────────────────────────────────────────────

  void _showFilterBottomSheet(BuildContext context) {
    ref.read(navbarVisibleProvider.notifier).hide();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setSheet) {
            void pick(String? v) {
              if (v == null) return;
              setSheet(() => _sortBy = v);
              setState(() {});
            }

            Widget sortOption(
              String value,
              String label, {
              bool enabled = true,
            }) {
              return DsCard(
                selected: _sortBy == value,
                onTap: enabled ? () => pick(value) : null,
                semanticLabel: label,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppFonts.body(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: enabled
                                  ? AppTheme.ink
                                  : AppTheme.textLight,
                            ),
                          ),
                          if (!enabled)
                            Text(
                              l.storeRequiresGps,
                              style: AppFonts.body(
                                fontSize: 13,
                                color: AppTheme.textLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_sortBy == value)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.forestDeep,
                      ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.storeFilterTitle,
                      style: AppFonts.display(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.storeMaxDistance(_customMaxRadiusKm.toStringAsFixed(0)),
                      style: AppFonts.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
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
                        setSheet(() => _customMaxRadiusKm = val);
                        setState(() {});
                      },
                    ),
                    if (!_userIsInDubai)
                      Text(
                        l.storeGpsOnlyNote,
                        style: AppFonts.body(
                          fontSize: 14,
                          color: AppTheme.textLight,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      l.storeSortBy,
                      style: AppFonts.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    sortOption(
                      'distance',
                      l.storeSortClosest,
                      enabled: _userIsInDubai,
                    ),
                    const SizedBox(height: 8),
                    sortOption('name', l.storeSortAlpha),
                    const SizedBox(height: 8),
                    sortOption('last_updated', l.storeSortRecent),
                    const SizedBox(height: 20),
                    DsButton(
                      label: l.storeApplyFilters,
                      onPressed: () => Navigator.pop(context),
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

// ── Map pin ──────────────────────────────────────────────────────────────────

/// A teardrop-style pin: the chain logo in a white circle with a coloured ring
/// (teal fresh, saffron older, grey stale) and a pointer to the exact spot.
class _StorePin extends StatelessWidget {
  const _StorePin({
    required this.store,
    required this.label,
    required this.onTap,
  });

  final Store store;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = store.lastUpdatedHoursAgo;
    final ring = h > 48
        ? const Color(0xFF8A8F94)
        : h > 24
        ? AppTheme.limeAccent
        : AppTheme.forestDeep;
    return Semantics(
      button: true,
      label: label.replaceAll('\n', ', '),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ring,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: DsStoreLogo(store.name, size: 42),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: ring, size: 24),
          ],
        ),
      ),
    );
  }
}

// ── List row ─────────────────────────────────────────────────────────────────

class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.store, required this.onTap, this.distanceKm});

  final Store store;
  final VoidCallback onTap;

  /// Null when the user is not in Dubai / location is off.
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final h = store.lastUpdatedHoursAgo;
    final tag = h > 48
        ? DsTag(l.storeStaleBadge, tone: DsTone.bad)
        : h > 24
        ? DsTag(store.freshness, tone: DsTone.warn)
        : DsTag(l.storeFresh, tone: DsTone.good);
    final meta = [
      if (distanceKm != null) l.storeDistanceKm(distanceKm!.toStringAsFixed(1)),
      l.storePricesCountLabel(store.pricesCount),
    ].join(' · ');

    return DsCard(
      onTap: onTap,
      semanticLabel: '${store.name}, ${store.branch}. $meta',
      child: Row(
        children: [
          DsStoreLogo(store.name, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.name}, ${store.branch}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(flex: 0, child: tag),
        ],
      ),
    );
  }
}
