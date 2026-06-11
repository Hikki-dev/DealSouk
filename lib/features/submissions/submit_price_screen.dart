import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/state.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';

class SubmitPriceScreen extends ConsumerStatefulWidget {
  const SubmitPriceScreen({super.key});

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
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stores = MockData.initialStores;
    final products = MockData.initialProducts;

    // Calculate dynamic tokens (1.5x multiplier with verified receipt per PRD FR-35)
    const int baseReward = 10;
    final int totalReward = uploadedReceipt ? (baseReward * 1.5).round() : baseReward;

    return ResponsiveContainer(
      appBar: AppBar(
        title: const Text('Submit Price'),
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
              // Info Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primaryContainer),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Earn rewards for submitting real-time grocery prices. Submit a photo of the price tag and the receipt for bonus tokens.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Supermarket Dropdown
              DropdownButtonFormField<String>(
                value: selectedStoreId,
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
                validator: (val) => val == null ? 'Please select a supermarket' : null,
              ),
              const SizedBox(height: 16),

              // Product Dropdown
              DropdownButtonFormField<String>(
                value: selectedProductId,
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
                validator: (val) => val == null ? 'Please select a product' : null,
              ),
              const SizedBox(height: 16),

              // Price Input
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Enter Price (AED)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'AED',
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
                value: selectedPromo,
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
                            'Estimated Tokens Reward',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.amberAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, color: AppTheme.amberAccent, size: 14),
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
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      _tokenRow('Base Submission Reward', '+10 tokens'),
                      const SizedBox(height: 8),
                      _tokenRow(
                        uploadedReceipt ? '1.5× Verified Receipt Multiplier' : 'Attach Receipt for 1.5× Bonus',
                        uploadedReceipt ? '×1.5 applied' : 'not applied',
                        isEnabled: uploadedReceipt,
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Reward Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$totalReward Tokens', style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 15)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit — lime pill CTA
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    final store = stores.firstWhere((s) => s.id == selectedStoreId);
                    final product = products.firstWhere((p) => p.id == selectedProductId);
                    final price = double.parse(_priceController.text);

                    // Add to admin submissions
                    ref.read(adminSubmissionsProvider.notifier).addSubmission(
                      productName: product.name,
                      brand: product.brand,
                      storeName: store.name,
                      price: price,
                      hasReceipt: uploadedReceipt,
                      hasPhoto: uploadedPriceLabel,
                      promoType: selectedPromo,
                      tokensReward: totalReward,
                    );

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
                        color: AppTheme.limeAccent.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Submit Price for Review',
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
          color: isUploaded ? AppTheme.emeraldLight.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUploaded ? AppTheme.emeraldPrimary : Colors.grey.shade300,
            width: isUploaded ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.camera_alt_outlined,
              color: isUploaded ? AppTheme.emeraldPrimary : Colors.grey.shade500,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUploaded ? AppTheme.emeraldPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isUploaded ? 'Photo Uploaded' : 'Tap to Upload',
              style: TextStyle(
                fontSize: 9,
                color: isUploaded ? AppTheme.emeraldPrimary.withOpacity(0.8) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, int reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              Text(
                'Your price submission has been sent to review.\n\n+$reward tokens will be credited to Hessa\'s account upon admin approval.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Pop dialog
                  context.pop(); // Pop submit screen
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        );
      },
    );
  }
}
