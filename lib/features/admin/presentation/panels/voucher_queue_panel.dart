import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/admin/domain/voucher_request.dart';

class VoucherQueuePanel extends ConsumerStatefulWidget {
  const VoucherQueuePanel({super.key, required this.vouchers});

  final List<VoucherRequest> vouchers;

  @override
  ConsumerState<VoucherQueuePanel> createState() => _VoucherQueuePanelState();
}

class _VoucherQueuePanelState extends ConsumerState<VoucherQueuePanel> {
  @override
  Widget build(BuildContext context) {
    final vouchers = widget.vouchers;
    if (vouchers.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEE4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.confirmation_num_outlined,
                size: 46,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No voucher requests',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'New requests appear here when shoppers reach the token threshold.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: vouchers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEE4)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.limeAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.confirmation_num_rounded,
                  color: AppTheme.forestDeep,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${voucher.userName} - AED ${voucher.denominationAed} ${voucher.supermarket}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${voucher.userHomeArea ?? 'Dubai'} | ${voucher.userTokenBalance} tokens available | cost ${voucher.tokenCost}',
                      style: GoogleFonts.nunito(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _reviewVoucher(voucher, approve: false),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _reviewVoucher(voucher, approve: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestDeep,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reviewVoucher(
    VoucherRequest voucher, {
    required bool approve,
  }) async {
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(approve ? 'Approve Voucher' : 'Reject Voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${voucher.userName} - AED ${voucher.denominationAed} ${voucher.supermarket}',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (approve) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A voucher code will be automatically selected and assigned from the active ${voucher.supermarket} (AED ${voucher.denominationAed}) inventory stock.',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin note',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppTheme.forestDeep : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (approve) {
        await ref
            .read(adminVouchersProvider.notifier)
            .approveVoucher(voucher.id, adminNote: noteCtrl.text.trim());
      } else {
        await ref
            .read(adminVouchersProvider.notifier)
            .rejectVoucher(voucher.id, adminNote: noteCtrl.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Voucher approved successfully!' : 'Voucher rejected.',
            ),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not review voucher: $err'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
