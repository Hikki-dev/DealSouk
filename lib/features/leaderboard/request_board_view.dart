import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/state.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';

class RequestBoardView extends ConsumerWidget {
  const RequestBoardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(priceRequestsProvider);
    final userTokens = ref.watch(userTokensProvider);

    final activeRequests = requests.where((r) => r.status == 'pending').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner explanation
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFECB3), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_center_rounded, color: AppTheme.amberAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Shoppers have posted bounties to verify prices at these stores. Visit a store, submit the price with a photo, and claim the tokens!',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Open Price Requests (${activeRequests.length})',
                style: GoogleFonts.fredoka(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRequestFormSheet(context, ref, userTokens),
                icon: const Icon(Icons.add_comment_rounded, size: 14),
                label: const Text('Request Price Check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (activeRequests.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    'All requests fulfilled!',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Post a new request if you need a price checked.',
                    style: GoogleFonts.nunito(color: Colors.grey, fontSize: 11.5),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeRequests.length,
              itemBuilder: (context, index) {
                final req = activeRequests[index];
                return _RequestItemCard(request: req);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showRequestFormSheet(BuildContext context, WidgetRef ref, int userTokens) {
    final formKey = GlobalKey<FormState>();
    String productName = '';
    String selectedStore = 'Carrefour';

    final List<String> stores = [
      'Carrefour',
      'Lulu Hypermarket',
      'Spinneys',
      'Union Coop',
      'Nesto',
      'Choithrams',
      'Grandiose',
      'Waitrose',
      'Al Maya',
      'Geant',
    ];

    final hasEnoughTokens = userTokens >= 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Request a Price Check',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestDeep,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bounty cost: 10 Tokens. Verified reports will deduct tokens from your balance.',
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade500,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Product Name Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'e.g. Al Rawabi Double Cream Cheese 500g',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.forestDeep),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                  onSaved: (val) => productName = val!.trim(),
                ),
                const SizedBox(height: 18),

                // Store Selection
                DropdownButtonFormField<String>(
                  initialValue: selectedStore,
                  decoration: InputDecoration(
                    labelText: 'Supermarket Chain',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: stores.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(s),
                    );
                  }).toList(),
                  onChanged: (val) => selectedStore = val!,
                ),
                const SizedBox(height: 24),

                if (!hasEnoughTokens)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Insufficient balance! You need 10 tokens to post a request. (Current balance: $userTokens)',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ElevatedButton(
                  onPressed: hasEnoughTokens
                      ? () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            
                            // Call provider method to request
                            ref.read(priceRequestsProvider.notifier).addPriceRequest(
                                  productName: productName,
                                  storeName: selectedStore,
                                  bounty: 10,
                                  requesterName: 'Hessa Al Maktoum',
                                );

                            Navigator.pop(context);
                            
                            // Success Dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Request Placed!'),
                                  ],
                                ),
                                content: Text(
                                  'Requested price verification of $productName at $selectedStore. 10 tokens have been deducted from your balance. Community members will notify you with the details shortly!',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Great'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestDeep,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Post Request (10 Tokens)'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  final PriceRequest request;

  const _RequestItemCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.limeAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_center_outlined, color: AppTheme.forestDeep, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${request.storeName} • ${request.distance} km • Posted by ${request.requesterName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amberLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.amberAccent, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '+${request.tokensBounty}',
                      style: const TextStyle(
                        color: Color(0xFFC77C02),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  // Navigate to submit price prefilled
                  context.push(
                    '/submit-price',
                    extra: {
                      'requestId': request.id,
                      'productName': request.productName,
                      'storeName': request.storeName,
                      'bounty': request.tokensBounty,
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.forestDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Fulfill',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
