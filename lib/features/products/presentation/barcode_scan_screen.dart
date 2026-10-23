import 'package:dealsouk/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/products/presentation/discover_strings.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  final bool returnScannedCode;

  /// Test hook: shown instead of the camera preview.
  final Widget? debugPreview;

  const BarcodeScanScreen({
    super.key,
    this.returnScannedCode = false,
    this.debugPreview,
  });

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  bool _handled = false;
  bool _typing = false;
  final _manual = TextEditingController();

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

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
    final l = AppLocalizations.of(context)!;
    final s = DiscoverStrings.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          l.scanBarcodeTitle,
          style: AppFonts.display(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child:
                widget.debugPreview ??
                MobileScanner(
                  onDetect: (capture) {
                    if (capture.barcodes.isEmpty) return;
                    final code = capture.barcodes.first.rawValue;
                    if (code != null) _handleCode(code);
                  },
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.scanBarcodeHint,
                        textAlign: TextAlign.center,
                        style: AppFonts.body(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
          ),
          Center(
            child: SizedBox(
              width: 280,
              height: 170,
              child: CustomPaint(painter: _FramePainter()),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.scanBarcodeHint,
                        textAlign: TextAlign.center,
                        style: AppFonts.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_typing) ...[
                        TextField(
                          controller: _manual,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSubmitted: _handleCode,
                          style: AppFonts.body(
                            fontSize: 18,
                            color: AppTheme.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: s.barcodeNumber,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DsButton(
                          label: s.search,
                          icon: Icons.search_rounded,
                          onPressed: () => _handleCode(_manual.text),
                        ),
                      ] else
                        DsButton(
                          label: s.typeBarcode,
                          style: DsButtonStyle.secondary,
                          icon: Icons.keyboard_rounded,
                          onPressed: () => setState(() => _typing = true),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four saffron corner brackets that frame the scan area.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.limeAccent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 34.0;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, len)
      ..lineTo(0, 0)
      ..lineTo(len, 0)
      ..moveTo(w - len, 0)
      ..lineTo(w, 0)
      ..lineTo(w, len)
      ..moveTo(w, h - len)
      ..lineTo(w, h)
      ..lineTo(w - len, h)
      ..moveTo(len, h)
      ..lineTo(0, h)
      ..lineTo(0, h - len);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
