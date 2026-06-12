import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/state.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';

class SubmitPriceScreen extends ConsumerStatefulWidget {
  final String? requestId;
  final String? prefilledProductName;
  final String? prefilledStoreName;
  final int? bounty;

  const SubmitPriceScreen({
    super.key,
    this.requestId,
    this.prefilledProductName,
    this.prefilledStoreName,
    this.bounty,
  });

  @override
  ConsumerState<SubmitPriceScreen> createState() => _SubmitPriceScreenState();
}

class _SubmitPriceScreenState extends ConsumerState<SubmitPriceScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedStoreId;
  String? selectedProductId;
  final _priceController = TextEditingController();

  bool uploadedPriceLabel = false;
  bool uploadedReceipt = false;
  String selectedPromo = 'None';

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() => setState(() {}));

    // Prefill fields if fulfilling a Request Board bounty
    if (widget.prefilledStoreName != null) {
      final match = MockData.initialStores.where(
        (s) => s.name.toLowerCase().contains(widget.prefilledStoreName!.toLowerCase()) ||
               widget.prefilledStoreName!.toLowerCase().contains(s.name.toLowerCase()),
      );
      if (match.isNotEmpty) {
        selectedStoreId = match.first.id;
      }
    }
    if (widget.prefilledProductName != null) {
      final match = MockData.initialProducts.where(
        (p) => p.name.toLowerCase().contains(widget.prefilledProductName!.toLowerCase()) ||
               widget.prefilledProductName!.toLowerCase().contains(p.name.toLowerCase()),
      );
      if (match.isNotEmpty) {
        selectedProductId = match.first.id;
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stores = MockData.initialStores;
    final products = MockData.initialProducts;
    final profile = ref.watch(userProfileProvider);
    final settings = ref.watch(adminSettingsProvider);

    final priceEntered = double.tryParse(_priceController.text.trim()) != null;
    final int baseReward = _tokenEstimateBeforeReceipt(priceEntered);
    var totalReward = uploadedReceipt
        ? (baseReward * 1.5).round()
        : baseReward;

    // Add active request bounty if fulfilling a request
    if (widget.bounty != null) {
      totalReward += widget.bounty!;
    }

    final int remainingToday = settings.dailySubmissionCap - profile.submissionsToday;

    return ResponsiveContainer(
      appBar: AppBar(
        title: const Text('Upload Price'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.forestDeep,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forestDeep.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppTheme.limeAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppTheme.forestDeep,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earn tokens nearby',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Upload a Dubai shelf label and optional receipt so the community sees fresher prices.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.limeAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.limeAccent.withValues(alpha: 0.65),
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
                        '$remainingToday of ${settings.dailySubmissionCap} submissions left today. Prices entered manually, not OCR-scanned.',
                        style: const TextStyle(
                          color: AppTheme.forestDeep,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Supermarket Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedStoreId,
                decoration: const InputDecoration(
                  labelText: 'Select Supermarket',
                  prefixIcon: Icon(Icons.store),
                ),
                items: stores.map((store) {
                  return DropdownMenuItem<String>(
                    value: store.id,
                    child: Text('${store.name} - ${store.branch}'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedStoreId = val;
                  });
                },
                validator: (val) =>
                    val == null ? 'Please select a supermarket' : null,
              ),
              const SizedBox(height: 16),

              // Product Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Select Product',
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                ),
                items: products.map((product) {
                  return DropdownMenuItem<String>(
                    value: product.id,
                    child: Text('${product.name} (${product.brand})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedProductId = val;
                  });
                },
                validator: (val) =>
                    val == null ? 'Please select a product' : null,
              ),
              const SizedBox(height: 16),

              // Price Input
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Enter Price (AED)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'AED',
                  helperText: 'Manual shelf price entry, e.g. AED 14.75',
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
              const SizedBox(height: 16),

              // Promo Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedPromo,
                decoration: const InputDecoration(
                  labelText: 'Promotion Type',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
                items: ['None', 'Discount', 'BOGO', 'Bundle'].map((promo) {
                  return DropdownMenuItem<String>(
                    value: promo,
                    child: Text(promo),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedPromo = val ?? 'None';
                  });
                },
              ),
              const SizedBox(height: 24),

              // Upload Photo Placeholders
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
                      title: 'Receipt Photo',
                      isUploaded: uploadedReceipt,
                      onTap: () {
                        setState(() {
                          uploadedReceipt = !uploadedReceipt;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Live Token Estimate Card
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
                              color: AppTheme.amberAccent.withValues(
                                alpha: 0.15,
                              ),
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
                      _tokenRow(
                        selectedStoreId == null
                            ? 'Choose store'
                            : 'Store selected',
                        selectedStoreId == null ? '+0 tokens' : '+2 tokens',
                        isEnabled: selectedStoreId != null,
                      ),
                      const SizedBox(height: 8),
                      _tokenRow(
                        selectedProductId == null
                            ? 'Choose product'
                            : 'Product selected',
                        selectedProductId == null ? '+0 tokens' : '+2 tokens',
                        isEnabled: selectedProductId != null,
                      ),
                      const SizedBox(height: 8),
                      _tokenRow(
                        priceEntered ? 'AED price entered' : 'Enter AED price',
                        priceEntered ? '+2 tokens' : '+0 tokens',
                        isEnabled: priceEntered,
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
              const SizedBox(height: 32),

              // Submit — lime pill CTA
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    final store = stores.firstWhere(
                      (s) => s.id == selectedStoreId,
                    );
                    final product = products.firstWhere(
                      (p) => p.id == selectedProductId,
                    );
                    final price = double.parse(_priceController.text);

                    // Add to admin submissions
                    ref
                        .read(adminSubmissionsProvider.notifier)
                        .addSubmission(
                          productName: product.name,
                          brand: product.brand,
                          storeName: store.name,
                          price: price,
                          hasReceipt: uploadedReceipt,
                          hasPhoto: uploadedPriceLabel,
                          promoType: selectedPromo,
                          tokensReward: totalReward,
                        );

                    // Award tokens immediately for demo flow
                    ref.read(userTokensProvider.notifier).addTokens(totalReward);
                    ref.read(userTransactionsProvider.notifier).addTransaction(
                      totalReward,
                      '+$totalReward tokens — submitted ${product.name} @ ${store.name}',
                    );

                    // Update profile and gamification state
                    ref.read(userProfileProvider.notifier).incrementSubmissions();
                    ref.read(streakProvider.notifier).recordActivity();
                    ref.read(dailyChallengeProvider.notifier).recordProgress();

                    // Fulfill the request if applicable
                    if (widget.requestId != null) {
                      ref.read(priceRequestsProvider.notifier).fulfillPriceRequest(widget.requestId!);
                    }

                    _showSuccessDialog(context, totalReward);
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
                  child: const Center(
                    child: Text(
                      'Send for review',
                      style: TextStyle(
                        color: AppTheme.forestDeep,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    required VoidCallback onTap,
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
