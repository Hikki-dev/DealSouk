import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  final bool returnScannedCode;

  const BarcodeScanScreen({super.key, this.returnScannedCode = false});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  bool _handled = false;

  void _handleCode(String code) {
    if (_handled || code.trim().isEmpty) return;
    _handled = true;
    final trimmed = code.trim();
    if (widget.returnScannedCode) {
      context.pop(trimmed);
      return;
    }
    ref.read(filterProvider.notifier).setSearchQuery(trimmed);
    context.go('/search');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final code = capture.barcodes.first.rawValue;
              if (code != null) _handleCode(code);
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.limeAccent, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 28,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Point the camera at the barcode. We will use it to find the product faster.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
