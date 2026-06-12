import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/admin/domain/admin_analytics.dart';
import 'package:dealsouk/features/admin/domain/admin_settings.dart';
import 'package:dealsouk/features/admin/domain/voucher_request.dart';
import 'package:dealsouk/features/admin/data/admin_service.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';

class AdminSubmissionsNotifier extends Notifier<List<AdminSubmission>> {
  @override
  List<AdminSubmission> build() => [];

  Future<void> fetchQueue() async {
    try {
      final results = await adminService.getQueue();
      state = results;
    } catch (_) {}
  }

  Future<void> approveSubmission(String id, WidgetRef ref) async {
    try {
      await adminService.approveSubmission(id);
      state = state.where((s) => s.id != id).toList();
      await ref.read(userTransactionsProvider.notifier).fetch();
      final profile = await profileService.getMyProfile();
      ref.read(userTokensProvider.notifier).sync(profile.tokenBalance);
    } catch (_) {
      state = state.where((s) => s.id != id).toList();
    }
  }

  Future<void> rejectSubmission(String id) async {
    try {
      await adminService.rejectSubmission(id);
    } catch (_) {}
    state = state.where((s) => s.id != id).toList();
  }

  Future<void> editSubmission(
    String id, {
    String? productName,
    String? storeName,
    double? price,
  }) async {
    try {
      await adminService.editSubmission(
        id,
        productName: productName,
        storeName: storeName,
        price: price,
      );
      state = state.map((s) {
        if (s.id == id) {
          return s.copyWith(
            productName: productName,
            storeName: storeName,
            price: price,
          );
        }
        return s;
      }).toList();
    } catch (_) {}
  }

  void addSubmission({
    required String productName,
    required String brand,
    required String storeName,
    required double price,
    required bool hasReceipt,
    required bool hasPhoto,
    required String promoType,
    required int tokensReward,
    String sourcerName = 'Shopper',
  }) {
    final newSub = AdminSubmission(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      productName: productName,
      brand: brand,
      storeName: storeName,
      price: price,
      hasReceipt: hasReceipt,
      hasPhoto: hasPhoto,
      promoType: promoType,
      tokensReward: tokensReward,
      timestampLabel: 'Just now',
      sourcerName: sourcerName,
      status: 'pending',
    );
    state = [newSub, ...state];
  }
}

final adminSubmissionsProvider =
    NotifierProvider<AdminSubmissionsNotifier, List<AdminSubmission>>(
      AdminSubmissionsNotifier.new,
    );

class AdminSettingsNotifier extends Notifier<AdminSettings> {
  @override
  AdminSettings build() => const AdminSettings();

  Future<void> fetchSettings() async {
    try {
      final settings = await adminService.getSettings();
      state = settings;
    } catch (_) {}
  }

  Future<void> setTokenEarnRate(int rate) async {
    state = state.copyWith(tokenEarnRate: rate);
    await adminService.updateSettings(state);
  }

  Future<void> setVoucherThreshold(int threshold) async {
    state = state.copyWith(voucherThreshold: threshold);
    await adminService.updateSettings(state);
  }

  Future<void> setDailySubmissionCap(int cap) async {
    state = state.copyWith(dailySubmissionCap: cap);
    await adminService.updateSettings(state);
  }

  Future<void> setRequestCostTokens(int cost) async {
    state = state.copyWith(requestCostTokens: cost);
    await adminService.updateSettings(state);
  }
}

final adminSettingsProvider =
    NotifierProvider<AdminSettingsNotifier, AdminSettings>(
      AdminSettingsNotifier.new,
    );

class AdminVouchersNotifier extends Notifier<List<VoucherRequest>> {
  @override
  List<VoucherRequest> build() => [];

  Future<void> fetchVouchers({String status = 'pending'}) async {
    try {
      state = await adminService.getVouchers(status: status);
    } catch (_) {}
  }

  Future<void> approveVoucher(
    String id, {
    required String voucherCode,
    String? adminNote,
  }) async {
    await adminService.approveVoucher(
      id,
      voucherCode: voucherCode,
      adminNote: adminNote,
    );
    state = state.where((voucher) => voucher.id != id).toList();
  }

  Future<void> rejectVoucher(String id, {String? adminNote}) async {
    await adminService.rejectVoucher(id, adminNote: adminNote);
    state = state.where((voucher) => voucher.id != id).toList();
  }
}

final adminVouchersProvider =
    NotifierProvider<AdminVouchersNotifier, List<VoucherRequest>>(
      AdminVouchersNotifier.new,
    );

class AdminAnalyticsNotifier extends Notifier<AdminAnalytics> {
  @override
  AdminAnalytics build() => AdminAnalytics.empty();

  Future<void> fetchAnalytics() async {
    try {
      state = await adminService.getAnalytics();
    } catch (_) {}
  }
}

final adminAnalyticsProvider =
    NotifierProvider<AdminAnalyticsNotifier, AdminAnalytics>(
      AdminAnalyticsNotifier.new,
    );
