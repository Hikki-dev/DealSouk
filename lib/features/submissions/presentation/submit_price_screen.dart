import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/l10n/app_localizations.dart';
import 'package:dealsouk/features/admin/domain/admin_settings.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/features/submissions/data/submissions_service.dart';
import 'package:dealsouk/core/offline/connectivity_service.dart';
import 'package:dealsouk/core/offline/sync_service.dart';
import 'package:dealsouk/core/network/storage_service.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/responsive_container.dart';
import 'package:dealsouk/core/util/geo_utils.dart';

class SubmitPriceScreen extends ConsumerStatefulWidget {
  final String? requestId;
  final String? prefilledProductName;
  final String? prefilledStoreName;

  const SubmitPriceScreen({
    super.key,
    this.requestId,
    this.prefilledProductName,
    this.prefilledStoreName,
  });

  @override
  ConsumerState<SubmitPriceScreen> createState() => _SubmitPriceScreenState();
}

class _SubmitPriceScreenState extends ConsumerState<SubmitPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productSearchController = TextEditingController();
  int _currentStep = 0;
  String _productSearchQuery = '';

  String? selectedStoreId;
  String? selectedProductId;
  final _priceController = TextEditingController();

  bool uploadedPriceLabel = false;
  bool uploadedReceipt = false;
  String? _receiptUrl;
  String? _priceLabelUrl;

  // Optimistic upload: local file available immediately after capture;
  // upload runs in background and URL resolves before final submit.
  XFile? _localPriceLabelFile;
  XFile? _localReceiptFile;
  Future<String?>? _priceLabelFuture;
  Future<String?>? _receiptFuture;
  bool _uploadingPriceLabel = false; // background upload in-flight
  bool _uploadingReceipt = false;
  bool _priceLabelUploadFailed = false;
  bool _receiptUploadFailed = false;
  bool _finalizingUploads = false; // brief wait on submit if still in-flight
  bool _isSubmitting = false; // API call in-flight

  String selectedPromo = 'None';

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() => setState(() {}));

    Future.microtask(() async {
      await ref.read(productsProvider.notifier).fetch();
      if (!mounted) return;
      final storesLoaded = ref.read(storesProvider);
      if (storesLoaded.isEmpty) {
        ref
            .read(storesProvider.notifier)
            .fetchNearby(lat: 25.0771, lng: 55.1328, radiusKm: 15);
      }

      if (widget.prefilledStoreName != null) {
        final stores = ref.read(storesProvider);
        final match = stores.where(
          (s) =>
              s.name.toLowerCase().contains(
                widget.prefilledStoreName!.toLowerCase(),
              ) ||
              widget.prefilledStoreName!.toLowerCase().contains(
                s.name.toLowerCase(),
              ),
        );
        if (match.isNotEmpty && mounted) {
          setState(() => selectedStoreId = match.first.id);
        }
      }
      if (widget.prefilledProductName != null) {
        final products = ref.read(productsProvider);
        final match = products.where(
          (p) =>
              p.name.toLowerCase().contains(
                widget.prefilledProductName!.toLowerCase(),
              ) ||
              widget.prefilledProductName!.toLowerCase().contains(
                p.name.toLowerCase(),
              ),
        );
        if (match.isNotEmpty && mounted) {
          setState(() => selectedProductId = match.first.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stores = ref.watch(storesProvider);
    final products = ref.watch(productsProvider);
    final profile = ref.watch(userProfileProvider);
    final settings = ref.watch(adminSettingsProvider);

    final priceEntered = double.tryParse(_priceController.text.trim()) != null;
    final int baseReward = _tokenEstimateBeforeReceipt(priceEntered);
    var totalReward = uploadedReceipt ? (baseReward * 1.5).round() : baseReward;

    final int remainingToday =
        settings.dailySubmissionCap - profile.submissionsToday;

    final filteredProducts = products.where((p) {
      final query = _productSearchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query);
    }).toList();

    return ResponsiveContainer(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentStep == 0
                ? l.submitStepSelectSupermarket
                : _currentStep == 1
                ? l.submitStepSelectProduct
                : _currentStep == 2
                ? l.submitStepEnterPrice
                : l.submitStepConfirmSubmit,
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const DirectionalIcon(Icons.arrow_back_ios_new_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                context.pop();
              }
            },
          ),
        ),
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4.0,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.limeAccent,
              ),
              minHeight: 6,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _buildStepContent(
                      stores: stores,
                      products: filteredProducts,
                      priceEntered: priceEntered,
                      totalReward: totalReward,
                      remainingToday: remainingToday,
                      settings: settings,
                      theme: theme,
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomActionBar(
              stores: stores,
              products: products,
              priceEntered: priceEntered,
              totalReward: totalReward,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  /// "branch • distance km away" using the user's REAL GPS position when
  /// available (same haversine the map uses), falling back to the backend's
  /// Dubai-relative distance only when location is unknown. The branch segment
  /// is dropped entirely when empty so there's no orphan separator.
  String _storeSubtitle(Store store) {
    final userPos = ref.read(userLocationProvider);
    final km = userPos != null
        ? haversineKm(userPos.latitude, userPos.longitude, store.lat, store.lng)
        : store.distance;
    // Whole-number km once we're far away (abroad testing); one decimal nearby.
    final distLabel = km >= 100
        ? '${km.toStringAsFixed(0)} km away'
        : '${km.toStringAsFixed(1)} km away';
    final branch = store.branch.trim();
    return branch.isEmpty ? distLabel : '$branch • $distLabel';
  }

  Widget _buildStepContent({
    required List<Store> stores,
    required List<Product> products,
    required bool priceEntered,
    required int totalReward,
    required int remainingToday,
    required AdminSettings settings,
    required ThemeData theme,
  }) {
    final l = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.submitWhereDidYouSeePrice,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.submitSelectSupermarketHint,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.limeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.limeAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.forestDeep,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.submitSubmissionsLeftToday(
                        remainingToday,
                        settings.dailySubmissionCap,
                      ),
                      style: const TextStyle(
                        color: AppTheme.forestDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (stores.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ...stores.map((store) {
                final isSelected = selectedStoreId == store.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.forestDeep
                          : const Color(0xFFFFE2BF),
                      width: isSelected ? 2 : 1.1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? AppTheme.cream
                          : Colors.grey.shade100,
                      child: Icon(
                        Icons.store_rounded,
                        color: isSelected ? AppTheme.forestDeep : Colors.grey,
                      ),
                    ),
                    title: Text(
                      store.name,
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textDark,
                      ),
                    ),
                    subtitle: Text(
                      _storeSubtitle(store),
                      style: GoogleFonts.nunito(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.forestDeep,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        selectedStoreId = store.id;
                      });
                    },
                  ),
                );
              }),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.submitWhichProduct,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.submitSearchSelectProductHint,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _productSearchController,
              decoration: InputDecoration(
                hintText: l.submitSearchBarcodeHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: l.submitScanBarcodeTooltip,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  onPressed: () async {
                    final code = await context.push<String>(
                      '/scan-barcode?return=1',
                    );
                    if (code == null || !mounted) return;
                    setState(() {
                      _productSearchQuery = code;
                      _productSearchController.text = code;
                    });
                  },
                ),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _productSearchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l.submitNoProductsFound,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = selectedProductId == product.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.forestDeep
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: SizedBox(
                          width: 36,
                          height: 36,
                          child: SoukProductVisual(
                            product: product,
                            borderRadius: 8,
                          ),
                        ),
                        title: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${product.brand} • ${product.packSize}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.forestDeep,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            selectedProductId = product.id;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Text(
              l.submitAttachProofRequired,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _photoUploadButton(
                    title: l.submitPriceLabelPhoto,
                    isUploaded: uploadedPriceLabel,
                    isUploading: _uploadingPriceLabel,
                    localFile: _localPriceLabelFile,
                    onTap: _uploadingPriceLabel
                        ? null
                        : () => _capturePhoto(isReceipt: false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _photoUploadButton(
                    title: l.submitReceiptPhoto,
                    isUploaded: uploadedReceipt,
                    isUploading: _uploadingReceipt,
                    localFile: _localReceiptFile,
                    onTap: _uploadingReceipt
                        ? null
                        : () => _capturePhoto(isReceipt: true),
                  ),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.submitEnterPriceDetails,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.submitEnterShelfPriceHint,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              decoration: InputDecoration(
                labelText: l.submitEnterPriceAed,
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixText: 'AED',
                helperText: l.submitManualShelfPriceHelper,
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return l.submitPleaseEnterPrice;
                }
                if (double.tryParse(val) == null) {
                  return l.submitPleaseEnterValidNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              l.submitPromotionType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['None', 'Discount', 'BOGO', 'Bundle'].map((promo) {
                final isSelected = selectedPromo == promo;
                return ChoiceChip(
                  label: Text(
                    _promoLabel(l, promo),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.forestDeep,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedPromo = promo;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
      case 3:
        final storesList = ref.read(storesProvider);
        final productsList = ref.read(productsProvider);
        // Guard against empty lists on cold start or connectivity loss (H-14).
        if (storesList.isEmpty || productsList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final store = storesList.firstWhere(
          (s) => s.id == selectedStoreId,
          orElse: () => storesList.first,
        );
        final product = productsList.firstWhere(
          (p) => p.id == selectedProductId,
          orElse: () => productsList.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.submitConfirmDetails,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.submitReviewBeforeSubmission,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFE2BF)),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    l.submitSummarySupermarket,
                    '${store.name} - ${store.branch}',
                  ),
                  const Divider(height: 24),
                  _summaryRow(l.submitSummaryProduct, product.name),
                  const Divider(height: 24),
                  _summaryRow(
                    l.submitSummaryPrice,
                    'AED ${_priceController.text}',
                  ),
                  const Divider(height: 24),
                  _summaryRow(
                    l.submitSummaryPromotion,
                    _promoLabel(l, selectedPromo),
                  ),
                  const Divider(height: 24),
                  _summaryRow(
                    l.submitSummaryProof,
                    uploadedPriceLabel
                        ? l.submitProofPhotoAttached
                        : l.submitPromoNone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.submitTokenRewardEstimate,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppTheme.forestDeep,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.amberAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: AppTheme.amberAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l.submitPlusTokens(totalReward),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFFC77C02),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _tokenRow(
                      l.submitTokenFreshShelfPrice,
                      l.submitTokensAmount(10),
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      l.submitTokenStoreSelected,
                      l.submitTokensAmount(2),
                      isEnabled: true,
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      l.submitTokenProductSelected,
                      l.submitTokensAmount(2),
                      isEnabled: true,
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      l.submitTokenAedPriceEntered,
                      l.submitTokensAmount(2),
                      isEnabled: true,
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      uploadedPriceLabel
                          ? l.submitTokenPriceLabelAttached
                          : l.submitTokenAttachPriceLabel,
                      uploadedPriceLabel
                          ? l.submitTokensAmount(4)
                          : l.submitTokensAmount(0),
                      isEnabled: uploadedPriceLabel,
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      selectedPromo == 'None'
                          ? l.submitTokenNoPromotion
                          : l.submitTokenPromoNoted(
                              _promoLabel(l, selectedPromo),
                            ),
                      selectedPromo == 'None'
                          ? l.submitTokensAmount(0)
                          : l.submitTokenAmount(1),
                      isEnabled: selectedPromo != 'None',
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      uploadedReceipt
                          ? l.submitTokenReceiptMultiplier
                          : l.submitTokenAttachReceiptBonus,
                      uploadedReceipt
                          ? l.submitTokenMultiplierApplied
                          : l.submitTokenNotApplied,
                      isEnabled: uploadedReceipt,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.submitTotalRewardEstimate,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l.submitTokensTotal(totalReward),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar({
    required List<Store> stores,
    required List<Product> products,
    required bool priceEntered,
    required int totalReward,
    required ThemeData theme,
  }) {
    final l = AppLocalizations.of(context)!;
    final bool canGoNext;
    if (_currentStep == 0) {
      canGoNext = selectedStoreId != null;
    } else if (_currentStep == 1) {
      canGoNext = selectedProductId != null && _localPriceLabelFile != null;
    } else if (_currentStep == 2) {
      canGoNext = priceEntered;
    } else {
      canGoNext = true;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: () {
                setState(() => _currentStep--);
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: Text(l.submitBack),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _currentStep < 3
                ? ElevatedButton(
                    onPressed: canGoNext
                        ? () {
                            if (_formKey.currentState!.validate() ||
                                _currentStep < 2) {
                              HapticFeedback.selectionClick();
                              setState(() => _currentStep++);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestDeep,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l.submitNext),
                  )
                : GestureDetector(
                    onTap: (_finalizingUploads || _isSubmitting)
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              // Await any background uploads still in-flight.
                              if (_uploadingPriceLabel || _uploadingReceipt) {
                                setState(() => _finalizingUploads = true);
                                if (_priceLabelFuture != null &&
                                    _priceLabelUrl == null) {
                                  _priceLabelUrl = await _priceLabelFuture;
                                }
                                if (_receiptFuture != null &&
                                    _receiptUrl == null) {
                                  _receiptUrl = await _receiptFuture;
                                }
                                if (!mounted) return;
                                setState(() => _finalizingUploads = false);
                              }

                              if (_priceLabelUrl == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.forestDeep,
                                    content: Text(l.submitProofPhotoRequired),
                                  ),
                                );
                                return;
                              }
                              if (uploadedReceipt && _receiptUrl == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.forestDeep,
                                    content: Text(l.submitReceiptPhotoRequired),
                                  ),
                                );
                                return;
                              }

                              final store = stores.firstWhere(
                                (s) => s.id == selectedStoreId,
                              );
                              final product = products.firstWhere(
                                (p) => p.id == selectedProductId,
                              );
                              final price = double.parse(_priceController.text);

                              // Offline (NFR-22): queue the submission and replay it
                              // on reconnect. Tokens are awarded after it syncs and is
                              // approved, so we don't credit them optimistically here.
                              if (!await isCurrentlyOnline()) {
                                await ref
                                    .read(syncControllerProvider.notifier)
                                    .enqueueSubmission(
                                      productId: selectedProductId!,
                                      storeId: selectedStoreId!,
                                      priceAed: price,
                                      hasReceipt: uploadedReceipt,
                                      receiptUrl: _receiptUrl,
                                      priceLabelUrl: _priceLabelUrl,
                                    );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.forestDeep,
                                    content: Text(l.submitSavedOffline),
                                  ),
                                );
                                context.pop();
                                return;
                              }

                              var awarded = 0;
                              var submissionStatus = 'pending';
                              setState(() => _isSubmitting = true);
                              try {
                                final result = await submissionsService.create(
                                  productId: selectedProductId!,
                                  storeId: selectedStoreId!,
                                  priceAed: price,
                                  hasReceipt: uploadedReceipt,
                                  receiptUrl: _receiptUrl,
                                  priceLabelUrl: _priceLabelUrl,
                                );
                                submissionStatus = result.status;
                                awarded = result.status == 'approved'
                                    ? result.tokensAwarded
                                    : 0;
                              } catch (_) {
                                if (!mounted) return;
                                setState(() => _isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.forestDeep,
                                    content: Text(l.submitCouldNotSendPrice),
                                  ),
                                );
                                return;
                              }
                              if (!mounted) return;
                              setState(() => _isSubmitting = false);

                              // Only trusted auto-approved submissions earn
                              // immediately. Normal submissions wait for admin
                              // approval, so the local balance must not fake it.
                              if (submissionStatus == 'approved' &&
                                  awarded > 0) {
                                ref
                                    .read(userTokensProvider.notifier)
                                    .addTokens(awarded);
                                ref
                                    .read(userTransactionsProvider.notifier)
                                    .addTransaction(
                                      awarded,
                                      l.submitTransactionDescription(
                                        awarded,
                                        product.name,
                                        store.name,
                                      ),
                                    );
                              }
                              ref
                                  .read(userProfileProvider.notifier)
                                  .incrementSubmissions();
                              if (submissionStatus == 'approved') {
                                ref
                                    .read(streakProvider.notifier)
                                    .recordActivity();
                                ref
                                    .read(dailyChallengeProvider.notifier)
                                    .recordProgress();
                              }

                              if (widget.requestId != null) {
                                ref
                                    .read(priceRequestsProvider.notifier)
                                    .fulfillPriceRequest(widget.requestId!);
                              }

                              // Reconcile optimistic updates with DB truth: pulls the
                              // real token balance, streak, accuracy, approved/total
                              // counts, token history, and the new row into "My
                              // Submissions". Keeps everything consistent across
                              // restarts and devices.
                              unawaited(
                                ref
                                    .read(authProvider.notifier)
                                    .refreshProfile(),
                              );

                              if (!mounted) return;
                              _showSuccessDialog(
                                context,
                                reward: awarded,
                                approvedNow: submissionStatus == 'approved',
                              );
                            }
                          },
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.limeAccent,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.limeAccent.withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: (_finalizingUploads || _isSubmitting)
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.forestDeep,
                                ),
                              )
                            : Text(
                                l.submitSubmitAPrice,
                                style: const TextStyle(
                                  color: AppTheme.forestDeep,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tokenRow(String title, String val, {bool isEnabled = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? Colors.black87 : Colors.grey,
            fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? AppTheme.emeraldPrimary : Colors.grey,
            fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _promoLabel(AppLocalizations l, String promo) {
    switch (promo) {
      case 'Discount':
        return l.submitPromoDiscount;
      case 'BOGO':
        return l.submitPromoBogo;
      case 'Bundle':
        return l.submitPromoBundle;
      case 'None':
      default:
        return l.submitPromoNone;
    }
  }

  int _tokenEstimateBeforeReceipt(bool priceEntered) {
    var reward = 10;
    if (selectedStoreId != null) reward += 2;
    if (selectedProductId != null) reward += 2;
    if (priceEntered) reward += 2;
    if (uploadedPriceLabel) reward += 4;
    if (selectedPromo != 'None') reward += 1;
    return reward;
  }

  /// Opens the camera for a proof photo. The local file is shown instantly
  /// (green checkmark) and the upload runs in the background. The URL is
  /// awaited only if still pending when the user taps final Submit.
  Future<void> _capturePhoto({required bool isReceipt}) async {
    final file = await storageService.capturePhotoFile();
    if (file == null || !mounted) return;

    // Snap feedback the instant the camera closes — feels immediate.
    unawaited(HapticFeedback.mediumImpact());

    final uploadFuture = storageService.uploadProofFile(
      file,
      isReceipt: isReceipt,
    );

    setState(() {
      if (isReceipt) {
        _localReceiptFile = file;
        uploadedReceipt = true;
        _receiptUploadFailed = false;
        _uploadingReceipt = true;
        _receiptFuture = uploadFuture;
      } else {
        _localPriceLabelFile = file;
        uploadedPriceLabel = true;
        _priceLabelUploadFailed = false;
        _uploadingPriceLabel = true;
        _priceLabelFuture = uploadFuture;
      }
    });

    // Resolve in background — clears the spinner and stores the URL.
    final url = await uploadFuture;
    if (!mounted) return;
    setState(() {
      if (isReceipt) {
        _uploadingReceipt = false;
        _receiptUrl = url;
        _receiptUploadFailed = url == null;
      } else {
        _uploadingPriceLabel = false;
        _priceLabelUrl = url;
        _priceLabelUploadFailed = url == null;
      }
    });

    if (url == null) {
      // Capture context refs before the await so we don't call into a disposed
      // widget tree if the screen was popped while the upload was in flight (H-13).
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final uploadFailedMsg = AppLocalizations.of(
        context,
      )!.submitPhotoUploadFailed;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.forestDeep,
          content: Text(uploadFailedMsg),
        ),
      );
    }
  }

  Widget _photoUploadButton({
    required String title,
    required bool isUploaded,
    required bool isUploading,
    XFile? localFile,
    VoidCallback? onTap,
  }) {
    final l = AppLocalizations.of(context)!;
    final failed =
        (title == l.submitPriceLabelPhoto && _priceLabelUploadFailed) ||
        (title == l.submitReceiptPhoto && _receiptUploadFailed);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: isUploaded
              ? AppTheme.limeAccent.withValues(alpha: 0.26)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: failed
                ? Colors.red.shade400
                : isUploaded
                ? AppTheme.forestDeep
                : Colors.grey.shade200,
            width: (isUploaded || failed) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: localFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(File(localFile.path), fit: BoxFit.cover),
                  ),
                  // Dark scrim at bottom for the retake hint
                  if (!isUploading)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          failed ? l.submitTapToRetry : l.submitTapToRetake,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Status badge (spinner or checkmark)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: isUploading
                        ? Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: failed
                                  ? Colors.red.shade600
                                  : AppTheme.forestDeep,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              failed
                                  ? Icons.priority_high_rounded
                                  : Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.grey.shade500,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.submitTapToUpload,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                ],
              ),
      ),
    );
  }

  void _showSuccessDialog(
    BuildContext context, {
    required int reward,
    required bool approvedNow,
  }) {
    final l = AppLocalizations.of(context)!;
    final profile = ref.read(userProfileProvider);
    final firstName = profile.name.split(' ').first;
    final isAdmin = ref.read(authProvider).isAdmin;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.emeraldLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.emeraldPrimary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.submitPriceSubmitted,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (approvedNow)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: reward.toDouble()),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Text(
                      l.submitTokensGained(value.round()),
                      style: const TextStyle(
                        color: AppTheme.forestDeep,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                )
              else
                Text(
                  l.submitAwaitingApproval,
                  style: const TextStyle(
                    color: AppTheme.forestDeep,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                approvedNow
                    ? l.submitApprovedNowMessage(firstName)
                    : l.submitPendingReviewMessage(firstName),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              if (isAdmin) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/admin');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l.submitOpenAdminReview),
                ),
                const SizedBox(height: 10),
              ],
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/leaderboard');
                },
                child: Text(l.submitViewTokenBalance),
              ),
            ],
          ),
        );
      },
    );
  }
}
