import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/l10n/app_localizations.dart';
import 'package:dealsouk/features/admin/domain/admin_settings.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
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
import 'package:dealsouk/core/design/design.dart';
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

    final stepTitle = _currentStep == 0
        ? l.submitStepSelectSupermarket
        : _currentStep == 1
        ? l.submitStepSelectProduct
        : _currentStep == 2
        ? l.submitStepEnterPrice
        : l.submitStepConfirmSubmit;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          stepTitle,
          style: AppFonts.display(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
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
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: DsStepBar(total: 4, current: _currentStep),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
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

  Widget _stepHeading(String title, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppFonts.display(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hint,
          style: AppFonts.body(
            fontSize: 16,
            height: 1.4,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
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
            _stepHeading(
              l.submitWhereDidYouSeePrice,
              l.submitSelectSupermarketHint,
            ),
            DsBanner(
              l.submitSubmissionsLeftToday(
                remainingToday,
                settings.dailySubmissionCap,
              ),
            ),
            const SizedBox(height: 16),
            if (stores.isEmpty)
              const Column(
                children: [
                  DsListRowSkeleton(),
                  SizedBox(height: 10),
                  DsListRowSkeleton(),
                  SizedBox(height: 10),
                  DsListRowSkeleton(),
                ],
              )
            else
              ...stores.map((store) {
                final isSelected = selectedStoreId == store.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DsCard(
                    selected: isSelected,
                    semanticLabel: store.name,
                    onTap: () => setState(() => selectedStoreId = store.id),
                    child: Row(
                      children: [
                        DsStoreLogo(store.name, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: AppFonts.display(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _storeSubtitle(store),
                                style: AppFonts.body(
                                  color: AppTheme.textLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.forestDeep,
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepHeading(l.submitWhichProduct, l.submitSearchSelectProductHint),
            TextField(
              controller: _productSearchController,
              style: AppFonts.body(fontSize: 17, color: AppTheme.ink),
              decoration: InputDecoration(
                hintText: l.submitSearchBarcodeHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: l.submitScanBarcodeTooltip,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
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
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
              ),
              onChanged: (val) => setState(() => _productSearchQuery = val),
            ),
            const SizedBox(height: 12),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l.submitNoProductsFound,
                    textAlign: TextAlign.center,
                    style: AppFonts.body(
                      color: AppTheme.textLight,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = selectedProductId == product.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DsCard(
                        selected: isSelected,
                        semanticLabel: product.name,
                        padding: const EdgeInsets.all(10),
                        onTap: () =>
                            setState(() => selectedProductId = product.id),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: SoukProductVisual(
                                product: product,
                                borderRadius: 10,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.body(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  Text(
                                    '${product.brand} • ${product.packSize}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.body(
                                      fontSize: 14,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.forestDeep,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Text(
              l.submitAttachProofRequired,
              style: AppFonts.body(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.ink,
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
                        : () {
                            if (_priceLabelUploadFailed &&
                                _localPriceLabelFile != null) {
                              unawaited(_retryPhotoUpload(isReceipt: false));
                            } else {
                              unawaited(_capturePhoto(isReceipt: false));
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _photoUploadButton(
                    title: l.submitReceiptPhoto,
                    isUploaded: uploadedReceipt,
                    isUploading: _uploadingReceipt,
                    localFile: _localReceiptFile,
                    onTap: _uploadingReceipt
                        ? null
                        : () {
                            if (_receiptUploadFailed &&
                                _localReceiptFile != null) {
                              unawaited(_retryPhotoUpload(isReceipt: true));
                            } else {
                              unawaited(_capturePhoto(isReceipt: true));
                            }
                          },
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
            _stepHeading(
              l.submitEnterPriceDetails,
              l.submitEnterShelfPriceHint,
            ),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppFonts.display(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
              decoration: InputDecoration(
                labelText: l.submitEnterPriceAed,
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixText: 'AED',
                helperText: l.submitManualShelfPriceHelper,
                helperMaxLines: 3,
                filled: true,
                fillColor: Colors.white,
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
              style: AppFonts.body(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['None', 'Discount', 'BOGO', 'Bundle'].map((promo) {
                return DsChip(
                  label: _promoLabel(l, promo),
                  selected: selectedPromo == promo,
                  onTap: () => setState(() => selectedPromo = promo),
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
            _stepHeading(
              l.submitConfirmDetails,
              l.submitReviewBeforeSubmission,
            ),
            DsCard(
              padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            DsCard(
              color: AppTheme.sand2,
              borderless: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.submitTokenRewardEstimate,
                          style: AppFonts.body(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.forestDeep,
                          ),
                        ),
                      ),
                      DsTag(
                        l.submitPlusTokens(totalReward),
                        tone: DsTone.warn,
                        icon: Icons.bolt_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _tokenRow(
                    l.submitTokenFreshShelfPrice,
                    l.submitTokensAmount(10),
                  ),
                  const SizedBox(height: 8),
                  _tokenRow(
                    l.submitTokenStoreSelected,
                    l.submitTokensAmount(2),
                  ),
                  const SizedBox(height: 8),
                  _tokenRow(
                    l.submitTokenProductSelected,
                    l.submitTokensAmount(2),
                  ),
                  const SizedBox(height: 8),
                  _tokenRow(
                    l.submitTokenAedPriceEntered,
                    l.submitTokensAmount(2),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppTheme.line),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.submitTotalRewardEstimate,
                          style: AppFonts.body(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      Text(
                        l.submitTokensTotal(totalReward),
                        style: AppFonts.display(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forestDeep,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppFonts.body(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppFonts.display(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.ink,
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
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                SizedBox(
                  width: 120,
                  child: DsButton(
                    label: l.submitBack,
                    style: DsButtonStyle.secondary,
                    onPressed: () => setState(() => _currentStep--),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _currentStep < 3
                    ? DsButton(
                        label: l.submitNext,
                        onPressed: canGoNext
                            ? () {
                                if (_formKey.currentState!.validate() ||
                                    _currentStep < 2) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _currentStep++);
                                }
                              }
                            : null,
                      )
                    : DsButton(
                        label: l.submitSubmitAPrice,
                        style: DsButtonStyle.accent,
                        loading: _finalizingUploads || _isSubmitting,
                        onPressed: () async {
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
                              if (_localPriceLabelFile != null) {
                                setState(() => _finalizingUploads = true);
                                await _retryPhotoUpload(
                                  isReceipt: false,
                                  showFailureSnackBar: false,
                                );
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
                            }
                            if (uploadedReceipt && _receiptUrl == null) {
                              if (_localReceiptFile != null) {
                                setState(() => _finalizingUploads = true);
                                await _retryPhotoUpload(
                                  isReceipt: true,
                                  showFailureSnackBar: false,
                                );
                                if (!mounted) return;
                                setState(() => _finalizingUploads = false);
                              }
                              if (_receiptUrl != null) {
                                // The retry recovered the optional receipt,
                                // so continue with final submission.
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.forestDeep,
                                    content: Text(l.submitReceiptPhotoRequired),
                                  ),
                                );
                                return;
                              }
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
                            if (submissionStatus == 'approved' && awarded > 0) {
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
                              ref.read(authProvider.notifier).refreshProfile(),
                            );

                            if (!mounted) return;
                            _showSuccessDialog(
                              context,
                              reward: awarded,
                              approvedNow: submissionStatus == 'approved',
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tokenRow(String title, String val, {bool isEnabled = true}) {
    final fg = isEnabled ? AppTheme.ink : AppTheme.textLight;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppFonts.body(
              fontSize: 14,
              color: fg,
              fontWeight: isEnabled ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          val,
          style: AppFonts.body(
            fontSize: 14,
            color: isEnabled ? AppTheme.forestDeep : AppTheme.textLight,
            fontWeight: isEnabled ? FontWeight.w700 : FontWeight.w400,
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

    await _startPhotoUpload(file, isReceipt: isReceipt);
  }

  Future<void> _retryPhotoUpload({
    required bool isReceipt,
    bool showFailureSnackBar = true,
  }) async {
    final file = isReceipt ? _localReceiptFile : _localPriceLabelFile;
    if (file == null) return;
    unawaited(HapticFeedback.selectionClick());
    await _startPhotoUpload(
      file,
      isReceipt: isReceipt,
      showFailureSnackBar: showFailureSnackBar,
    );
  }

  Future<void> _startPhotoUpload(
    XFile file, {
    required bool isReceipt,
    bool showFailureSnackBar = true,
  }) async {
    final uploadFuture = storageService.uploadProofFile(
      file,
      isReceipt: isReceipt,
    );

    setState(() {
      if (isReceipt) {
        _localReceiptFile = file;
        uploadedReceipt = true;
        _receiptUploadFailed = false;
        _receiptUrl = null;
        _uploadingReceipt = true;
        _receiptFuture = uploadFuture;
      } else {
        _localPriceLabelFile = file;
        uploadedPriceLabel = true;
        _priceLabelUploadFailed = false;
        _priceLabelUrl = null;
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

    if (url == null && showFailureSnackBar) {
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
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: Material(
        color: isUploaded ? AppTheme.emeraldLight : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: failed
                ? AppTheme.redAccent
                : isUploaded
                ? AppTheme.forestDeep
                : AppTheme.line,
            width: (isUploaded || failed) ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 132,
            child: localFile != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(localFile.path),
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                      ),
                      if (!isUploading)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              failed ? l.submitTapToRetry : l.submitTapToRetake,
                              textAlign: TextAlign.center,
                              style: AppFonts.body(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: isUploading
                            ? Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: failed
                                      ? AppTheme.redAccent
                                      : AppTheme.forestDeep,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  failed
                                      ? Icons.priority_high_rounded
                                      : Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: AppTheme.forestDeep,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppFonts.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          l.submitTapToUpload,
                          textAlign: TextAlign.center,
                          style: AppFonts.body(
                            fontSize: 13,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
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
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.goodLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.good,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.submitPriceSubmitted,
                  textAlign: TextAlign.center,
                  style: AppFonts.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
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
                        textAlign: TextAlign.center,
                        style: AppFonts.display(
                          color: AppTheme.forestDeep,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  )
                else
                  Text(
                    l.submitAwaitingApproval,
                    textAlign: TextAlign.center,
                    style: AppFonts.display(
                      color: AppTheme.forestDeep,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  approvedNow
                      ? l.submitApprovedNowMessage(firstName)
                      : l.submitPendingReviewMessage(firstName),
                  textAlign: TextAlign.center,
                  style: AppFonts.body(
                    fontSize: 15,
                    height: 1.4,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 20),
                if (isAdmin) ...[
                  DsButton(
                    label: l.submitOpenAdminReview,
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/admin');
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                DsButton(
                  label: l.submitViewTokenBalance,
                  style: isAdmin ? DsButtonStyle.ghost : DsButtonStyle.primary,
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/leaderboard');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
