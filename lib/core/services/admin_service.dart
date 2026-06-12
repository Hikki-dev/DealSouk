import '../models/models.dart';
import 'api_client.dart';

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
    await apiClient.post('/admin/submissions/$id/reject', data: {
      'reason': ?reason,
    });
  }

  Future<void> editSubmission(String id, {
    String? productName,
    String? storeName,
    double? price,
  }) async {
    await apiClient.patch('/admin/submissions/$id', data: {
      'productName': ?productName,
      'storeName': ?storeName,
      'priceAed': ?price,
    });
  }

  Future<AdminSettings> getSettings() async {
    final res = await apiClient.get('/admin/settings');
    final data = res.data as Map<String, dynamic>;
    return AdminSettings(
      tokenEarnRate: data['tokenEarnRate'] as int? ?? 50,
      voucherThreshold: data['voucherThreshold'] as int? ?? 500,
      dailySubmissionCap: data['dailySubmissionCap'] as int? ?? 30,
    );
  }

  Future<void> updateSettings(AdminSettings settings) async {
    await apiClient.patch('/admin/settings', data: {
      'tokenEarnRate': settings.tokenEarnRate,
      'voucherThreshold': settings.voucherThreshold,
      'dailySubmissionCap': settings.dailySubmissionCap,
    });
  }
}

final adminService = AdminService();
