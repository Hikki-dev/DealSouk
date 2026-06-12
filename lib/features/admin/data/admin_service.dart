import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/admin/domain/admin_analytics.dart';
import 'package:dealsouk/features/admin/domain/admin_settings.dart';
import 'package:dealsouk/features/admin/domain/voucher_request.dart';
import 'package:dealsouk/core/network/api_client.dart';

class AdminService {
  Future<List<AdminSubmission>> getQueue() async {
    final res = await apiClient.get('/admin/queue');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AdminSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveSubmission(String id) async {
    await apiClient.post('/admin/submissions/$id/approve');
  }

  Future<void> rejectSubmission(String id, {String? reason}) async {
    await apiClient.post(
      '/admin/submissions/$id/reject',
      data: {'reason': ?reason},
    );
  }

  Future<void> editSubmission(
    String id, {
    String? productName,
    String? storeName,
    double? price,
  }) async {
    await apiClient.patch(
      '/admin/submissions/$id',
      data: {
        'productName': ?productName,
        'storeName': ?storeName,
        'priceAed': ?price,
      },
    );
  }

  Future<AdminSettings> getSettings() async {
    final res = await apiClient.get('/admin/settings');
    final data = res.data as Map<String, dynamic>;
    return AdminSettings(
      tokenEarnRate: data['tokenEarnRate'] as int? ?? 50,
      voucherThreshold: data['voucherThreshold'] as int? ?? 500,
      dailySubmissionCap: data['dailySubmissionCap'] as int? ?? 30,
      requestCostTokens: data['requestCostTokens'] as int? ?? 10,
    );
  }

  Future<void> updateSettings(AdminSettings settings) async {
    await apiClient.patch(
      '/admin/settings',
      data: {
        'tokenEarnRate': settings.tokenEarnRate,
        'voucherThreshold': settings.voucherThreshold,
        'dailySubmissionCap': settings.dailySubmissionCap,
        'requestCostTokens': settings.requestCostTokens,
      },
    );
  }

  Future<List<VoucherRequest>> getVouchers({String status = 'pending'}) async {
    final res = await apiClient.get(
      '/admin/vouchers',
      params: {'status': status},
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => VoucherRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminAnalytics> getAnalytics() async {
    final res = await apiClient.get('/admin/analytics');
    return AdminAnalytics.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> approveVoucher(
    String id, {
    required String voucherCode,
    String? adminNote,
  }) async {
    await apiClient.post(
      '/admin/vouchers/$id/approve',
      data: {'voucherCode': voucherCode, 'adminNote': ?adminNote},
    );
  }

  Future<void> rejectVoucher(String id, {String? adminNote}) async {
    await apiClient.post(
      '/admin/vouchers/$id/reject',
      data: {'adminNote': ?adminNote},
    );
  }
}

final adminService = AdminService();
