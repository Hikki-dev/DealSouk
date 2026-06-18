import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';

class VoucherStockPanel extends ConsumerWidget {
  const VoucherStockPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(adminVoucherInventoryProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voucher Stock Levels',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showImportVouchersDialog(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Import Voucher Codes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: inventory.isEmpty
                ? Center(
                    child: Text(
                      'No voucher stock records. Click import to add voucher codes.',
                      style: GoogleFonts.nunito(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: inventory.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = inventory[index] as Map<String, dynamic>;
                      final supermarket =
                          item['supermarket'] as String? ?? 'Unknown';
                      final denom = item['denominationAed'] as int? ?? 50;
                      final count = item['count'] as int? ?? 0;
                      final isUsed = item['isUsed'] as bool? ?? false;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EEE4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isUsed
                                        ? Colors.grey.shade100
                                        : AppTheme.limeAccent.withValues(
                                            alpha: 0.2,
                                          )),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.confirmation_num_rounded,
                                    color: isUsed
                                        ? Colors.grey
                                        : AppTheme.forestDeep,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$supermarket (AED $denom)',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isUsed
                                          ? 'Used Vouchers'
                                          : 'Available Unused Stock',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isUsed
                                    ? Colors.grey.shade100
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count codes',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900,
                                  color: isUsed
                                      ? Colors.grey.shade700
                                      : Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showImportVouchersDialog(BuildContext context, WidgetRef ref) {
    final supermarketCtrl = TextEditingController();
    final denomCtrl = TextEditingController(text: '50');
    final codesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Import Voucher Codes',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: supermarketCtrl,
                  decoration: const InputDecoration(
                    labelText:
                        'Supermarket Name (e.g. Carrefour, LuLu, Spinneys)',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: denomCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Denomination (AED)',
                    prefixIcon: Icon(Icons.money_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codesCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Voucher Codes (one per line, min 4 chars)',
                    hintText: 'CODE123\nCODE456\nCODE789',
                    prefixIcon: Icon(Icons.confirmation_num_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final supermarket = supermarketCtrl.text.trim();
                final denom = int.tryParse(denomCtrl.text.trim()) ?? 50;
                final rawCodes = codesCtrl.text.trim().split('\n');
                final codes = rawCodes
                    .map((c) => c.trim())
                    .where((c) => c.length >= 4)
                    .toList();

                if (supermarket.isEmpty || codes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill out supermarket and enter valid codes.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                try {
                  await ref
                      .read(adminVoucherInventoryProvider.notifier)
                      .importVouchers(
                        supermarket: supermarket,
                        denominationAed: denom,
                        codes: codes,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vouchers imported successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to import vouchers: $err'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestDeep,
                foregroundColor: Colors.white,
              ),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }
}
