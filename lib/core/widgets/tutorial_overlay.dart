import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const TutorialOverlay(),
    );
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialSlide> _slides = [
    const _TutorialSlide(
      title: "Compare Grocery Prices",
      description:
          "Find nearby prices for fruits, vegetables, dairy, and snacks in Dubai supermarkets before you leave home.",
    ),
    const _TutorialSlide(
      title: "Ask For Price Checks",
      description:
          "Need a price you cannot see? Ask the community to check it, or help others by sharing a shelf price.",
    ),
    const _TutorialSlide(
      title: "Earn Shopping Rewards",
      description:
          "Share prices or check shelves to earn tokens, then swap them for real supermarket vouchers.",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSlideVisual(int index) {
    switch (index) {
      case 0:
        return _buildCompareVisual();
      case 1:
        return _buildSubmitVisual();
      case 2:
        return _buildRedeemVisual();
      default:
        return Container();
    }
  }

  Widget _buildCompareVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apple, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Fuji Apples',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    'Pack size: 1 kg',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Price rows
          _buildMiniPriceRow('Union Coop', 'AED 3.95', isCheapest: true),
          const SizedBox(height: 5),
          _buildMiniPriceRow('Carrefour', 'AED 4.50'),
          const SizedBox(height: 5),
          _buildMiniPriceRow('Spinneys', 'AED 5.25'),
        ],
      ),
    );
  }

  Widget _buildMiniPriceRow(
    String store,
    String price, {
    bool isCheapest = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isCheapest
                  ? Icons.check_circle_rounded
                  : Icons.storefront_outlined,
              size: 14,
              color: isCheapest
                  ? AppTheme.emeraldPrimary
                  : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              store,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCheapest ? FontWeight.bold : FontWeight.normal,
                color: isCheapest ? AppTheme.emeraldPrimary : AppTheme.textDark,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              price,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isCheapest ? AppTheme.emeraldPrimary : AppTheme.textDark,
              ),
            ),
            if (isCheapest) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CHEAPEST',
                  style: TextStyle(
                    color: AppTheme.forestDeep,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Submission',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.amberLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: AppTheme.amberAccent, size: 10),
                    SizedBox(width: 2),
                    Text(
                      '+15 Tokens',
                      style: TextStyle(
                        color: Color(0xFFC77C02),
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          // Store Name
          Text(
            'Union Coop - Al Barsha',
            style: TextStyle(
              fontSize: 9.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // Price field mock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price per item',
                  style: TextStyle(fontSize: 9.5, color: Colors.black54),
                ),
                Text(
                  'AED 3.90',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Evidence mock
          Row(
            children: [
              _buildMiniEvidenceChip(Icons.camera_alt_rounded, 'Label.jpg'),
              const SizedBox(width: 6),
              _buildMiniEvidenceChip(Icons.receipt_long_rounded, 'Receipt.jpg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniEvidenceChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.forestDeep, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.forestDeep,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voucher description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.amberLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_num_rounded,
                  color: AppTheme.amberAccent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Union Coop Voucher',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Value: AED 50.00',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.forestDeep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mock Barcode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(20, (index) {
                    final double width = (index % 3 == 0)
                        ? 2.5
                        : (index % 2 == 0)
                        ? 1.5
                        : 0.8;
                    return Container(
                      width: width,
                      height: 20,
                      margin: const EdgeInsets.only(right: 1.2),
                      color: Colors.black87,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                const Text(
                  'DS-50-UCOOP-8X92',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 16,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 540),
        child: Column(
          children: [
            // Close button in top-right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 12),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // PageView content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // High-Fidelity UI Piece
                        Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: _buildSlideVisual(index),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots indicator & CTA Row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Dots Indicator
                  Row(
                    children: List.generate(_slides.length, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 7,
                        width: isSelected ? 20 : 7,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.forestDeep
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Done button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestDeep,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'Start' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
}

class _TutorialSlide {
  final String title;
  final String description;

  const _TutorialSlide({required this.title, required this.description});
}
