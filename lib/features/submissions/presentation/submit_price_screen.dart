import 'package:dealsouk/core/widgets/souk_widgets.dart';
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
import 'package:dealsouk/core/network/storage_service.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/responsive_container.dart';

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
  int _currentStep = 0;
  String _productSearchQuery = '';

  String? selectedStoreId;
  String? selectedProductId;
  final _priceController = TextEditingController();

  bool uploadedPriceLabel = false;
  bool uploadedReceipt = false;
  String? _receiptUrl;
  bool _uploadingReceipt = false;
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
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          p.category.toLowerCase().contains(query);
    }).toList();

    return ResponsiveContainer(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentStep == 0
                ? 'Select Supermarket'
                : _currentStep == 1
                ? 'Select Product'
                : _currentStep == 2
                ? 'Enter Price'
                : 'Confirm & submit',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
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

  Widget _buildStepContent({
    required List<Store> stores,
    required List<Product> products,
    required bool priceEntered,
    required int totalReward,
    required int remainingToday,
    required AdminSettings settings,
    required ThemeData theme,
  }) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Where did you see the price?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select the supermarket from the nearby list.',
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
                      '$remainingToday of ${settings.dailySubmissionCap} submissions left today.',
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
                      '${store.branch} • ${store.distance.toStringAsFixed(1)} km away',
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
            const Text(
              'Which product is it?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Search or select product and attach proof photo.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search product by name or brand...',
                prefixIcon: const Icon(Icons.search_rounded),
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
                    'No products found matching your search.',
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
            const Text(
              'Attach Proof (Required)',
              style: TextStyle(
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
                    title: 'Price Label Photo',
                    isUploaded: uploadedPriceLabel,
                    onTap: () {
                      setState(() {
                        uploadedPriceLabel = !uploadedPriceLabel;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _photoUploadButton(
                    title: _uploadingReceipt ? 'Uploading…' : 'Receipt Photo',
                    isUploaded: uploadedReceipt,
                    onTap: _uploadingReceipt
                        ? null
                        : () async {
                            setState(() => _uploadingReceipt = true);
                            final url = await storageService
                                .captureAndUploadReceipt();
                            if (mounted) {
                              setState(() {
                                _uploadingReceipt = false;
                                if (url != null) {
                                  _receiptUrl = url;
                                  uploadedReceipt = true;
                                }
                              });
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
            const Text(
              'Enter Price details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the shelf price and active promotions.',
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
              decoration: const InputDecoration(
                labelText: 'Enter Price (AED)',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: 'AED',
                helperText: 'Manual shelf price entry, e.g. 14.75',
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(val) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Promotion Type',
              style: TextStyle(
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
                    promo,
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
            const Text(
              'Confirm details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please review details before submission.',
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
                  _summaryRow('Supermarket', '${store.name} - ${store.branch}'),
                  const Divider(height: 24),
                  _summaryRow('Product', product.name),
                  const Divider(height: 24),
                  _summaryRow('Price', 'AED ${_priceController.text}'),
                  const Divider(height: 24),
                  _summaryRow('Promotion', selectedPromo),
                  const Divider(height: 24),
                  _summaryRow(
                    'Proof',
                    uploadedPriceLabel ? 'Photo Attached' : 'None',
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
                        const Text(
                          'Token reward estimate',
                          style: TextStyle(
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
                                '+$totalReward Tokens',
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
                    _tokenRow('Fresh shelf price', '+10 tokens'),
                    const SizedBox(height: 8),
                    _tokenRow('Store selected', '+2 tokens', isEnabled: true),
                    const SizedBox(height: 8),
                    _tokenRow('Product selected', '+2 tokens', isEnabled: true),
                    const SizedBox(height: 8),
                    _tokenRow(
                      'AED price entered',
                      '+2 tokens',
                      isEnabled: true,
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      uploadedPriceLabel
                          ? 'Price label attached'
                          : 'Attach price label',
                      uploadedPriceLabel ? '+4 tokens' : '+0 tokens',
                      isEnabled: uploadedPriceLabel,
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      selectedPromo == 'None'
                          ? 'No promotion selected'
                          : '$selectedPromo promo noted',
                      selectedPromo == 'None' ? '+0 tokens' : '+1 token',
                      isEnabled: selectedPromo != 'None',
                    ),
                    const SizedBox(height: 8),
                    _tokenRow(
                      uploadedReceipt
                          ? '1.5× Verified Receipt Multiplier'
                          : 'Attach Receipt for 1.5× Bonus',
                      uploadedReceipt ? '×1.5 applied' : 'not applied',
                      isEnabled: uploadedReceipt,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Reward Estimate',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$totalReward Tokens',
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
    final bool canGoNext;
    if (_currentStep == 0) {
      canGoNext = selectedStoreId != null;
    } else if (_currentStep == 1) {
      canGoNext = selectedProductId != null && uploadedPriceLabel;
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
              child: const Text('Back'),
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
                    child: const Text('Next'),
                  )
                : GestureDetector(
                    onTap: () async {
                      if (_formKey.currentState!.validate()) {
                        final store = stores.firstWhere(
                          (s) => s.id == selectedStoreId,
                        );
                        final product = products.firstWhere(
                          (p) => p.id == selectedProductId,
                        );
                        final price = double.parse(_priceController.text);

                        int awarded = totalReward;
                        try {
                          final result = await submissionsService.create(
                            productId: selectedProductId!,
                            storeId: selectedStoreId!,
                            priceAed: price,
                            hasReceipt: uploadedReceipt,
                            receiptUrl: _receiptUrl,
                          );
                          awarded = result.tokensAwarded;
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.forestDeep,
                              content: Text(
                                'We could not send this price. Please check your connection and try again.',
                              ),
                            ),
                          );
                          return;
                        }

                        // Optimistic UI updates
                        ref
                            .read(userTokensProvider.notifier)
                            .addTokens(awarded);
                        ref
                            .read(userTransactionsProvider.notifier)
                            .addTransaction(
                              awarded,
                              '+$awarded tokens — submitted ${product.name} @ ${store.name}',
                            );
                        ref
                            .read(userProfileProvider.notifier)
                            .incrementSubmissions();
                        ref.read(streakProvider.notifier).recordActivity();
                        ref
                            .read(dailyChallengeProvider.notifier)
                            .recordProgress();

                        if (widget.requestId != null) {
                          ref
                              .read(priceRequestsProvider.notifier)
                              .fulfillPriceRequest(widget.requestId!);
                        }

                        if (!mounted) return;
                        _showSuccessDialog(context, awarded);
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
                        child: Text(
                          'Submit a price',
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

  int _tokenEstimateBeforeReceipt(bool priceEntered) {
    var reward = 10;
    if (selectedStoreId != null) reward += 2;
    if (selectedProductId != null) reward += 2;
    if (priceEntered) reward += 2;
    if (uploadedPriceLabel) reward += 4;
    if (selectedPromo != 'None') reward += 1;
    return reward;
  }

  Widget _photoUploadButton({
    required String title,
    required bool isUploaded,
    VoidCallback? onTap,
  }) {
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
            color: isUploaded ? AppTheme.forestDeep : Colors.grey.shade200,
            width: isUploaded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.camera_alt_outlined,
              color: isUploaded ? AppTheme.forestDeep : Colors.grey.shade500,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUploaded ? AppTheme.forestDeep : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isUploaded ? 'Photo Uploaded' : 'Tap to Upload',
              style: TextStyle(
                fontSize: 9,
                color: isUploaded
                    ? AppTheme.forestDeep.withValues(alpha: 0.8)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, int reward) {
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
              const Text(
                'Price Submitted!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: reward.toDouble()),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Text(
                    '+${value.round()} tokens',
                    style: const TextStyle(
                      color: AppTheme.forestDeep,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Your price submission is pending review.\nTokens will be credited to $firstName after admin approval.',
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
                  child: const Text('Open Admin Review'),
                ),
                const SizedBox(height: 10),
              ],
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/leaderboard');
                },
                child: const Text('View Token Balance'),
              ),
            ],
          ),
        );
      },
    );
  }
}
