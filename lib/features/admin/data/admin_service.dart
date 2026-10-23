import 'package:dio/dio.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/admin/domain/admin_analytics.dart';
import 'package:dealsouk/features/admin/domain/admin_settings.dart';
import 'package:dealsouk/features/admin/domain/voucher_request.dart';
import 'package:dealsouk/core/network/api_client.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';

/// Thrown instead of calling the API when the console is in demo (view-only) mode.
class AdminReadOnlyException implements Exception {
  const AdminReadOnlyException();
  @override
  String toString() =>
      'Demo mode is view-only. Only the owner can make changes.';
}

class AdminService {
  /// True for demo viewers. The API refuses their writes anyway; this just gives
  /// a clear message without a round trip.
  bool readOnly = false;

  void _guardWrite() {
    if (readOnly) throw const AdminReadOnlyException();
  }

  Future<List<AdminSubmission>> getQueue() async {
    final res = await apiClient.get('/admin/queue');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AdminSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveSubmission(String id, {String? productImageUrl}) async {
    _guardWrite();
    await apiClient.post(
      '/admin/submissions/$id/approve',
      data: {'productImageUrl': ?productImageUrl},
    );
  }

  Future<void> rejectSubmission(String id, {String? reason}) async {
    _guardWrite();
    await apiClient.post(
      '/admin/submissions/$id/reject',
      data: {'reason': ?reason},
    );
  }

  Future<void> editSubmission(
    String id, {
    String? productName,
    String? storeName,
    String? productImageUrl,
    double? price,
  }) async {
    _guardWrite();
    await apiClient.patch(
      '/admin/submissions/$id',
      data: {
        'productName': ?productName,
        'storeName': ?storeName,
        'productImageUrl': ?productImageUrl,
        'priceAed': ?price,
      },
    );
  }

  Future<void> warnUser(String userId, {required String reason}) async {
    _guardWrite();
    await apiClient.post('/admin/users/$userId/warn', data: {'reason': reason});
  }

  Future<void> suspendUser(
    String userId, {
    required String reason,
    int days = 7,
  }) async {
    _guardWrite();
    await apiClient.post(
      '/admin/users/$userId/suspend',
      data: {'reason': reason, 'days': days},
    );
  }

  Future<void> banUser(String userId, {required String reason}) async {
    _guardWrite();
    await apiClient.post('/admin/users/$userId/ban', data: {'reason': reason});
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
    _guardWrite();
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
    _guardWrite();
    await apiClient.post(
      '/admin/vouchers/$id/approve',
      data: {'voucherCode': voucherCode, 'adminNote': ?adminNote},
    );
  }

  Future<void> rejectVoucher(String id, {String? adminNote}) async {
    _guardWrite();
    await apiClient.post(
      '/admin/vouchers/$id/reject',
      data: {'adminNote': ?adminNote},
    );
  }

  // New Voucher Stock management methods
  Future<void> importVouchers({
    required String supermarket,
    required int denominationAed,
    required List<String> codes,
  }) async {
    _guardWrite();
    await apiClient.post(
      '/admin/vouchers/inventory/import',
      data: {
        'supermarket': supermarket,
        'denominationAed': denominationAed,
        'codes': codes,
      },
    );
  }

  Future<List<dynamic>> getVoucherInventoryStatus() async {
    final res = await apiClient.get('/admin/vouchers/inventory/status');
    return res.data as List<dynamic>;
  }

  // New map density endpoint
  Future<List<dynamic>> getMapData() async {
    final res = await apiClient.get('/admin/map-data');
    return res.data as List<dynamic>;
  }

  // PDF Download endpoint
  Future<List<int>> downloadAnalyticsPdf() async {
    final res = await apiClient.get(
      '/admin/exports/analytics.pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return List<int>.from(res.data as List<dynamic>);
  }

  // Products CRUD
  Future<Map<String, dynamic>> getProducts({
    String query = '',
    String? category,
    int page = 0,
  }) async {
    final res = await apiClient.get(
      '/admin/products',
      params: {
        'q': query,
        if (category != null && category != 'All') 'category': category,
        'page': page,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final list = data['products'] as List<dynamic>;
    final productsList = list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    return {'products': productsList, 'total': data['total'] as int? ?? 0};
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    _guardWrite();
    final res = await apiClient.post('/admin/products', data: data);
    return Product.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    _guardWrite();
    final res = await apiClient.put('/admin/products/$id', data: data);
    return Product.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) async {
    _guardWrite();
    await apiClient.delete('/admin/products/$id');
  }

  // Users CRUD
  Future<Map<String, dynamic>> getUsers({
    String query = '',
    int page = 0,
  }) async {
    final res = await apiClient.get(
      '/admin/users',
      params: {'q': query, 'page': page},
    );
    final data = res.data as Map<String, dynamic>;
    final list = data['users'] as List<dynamic>;
    final usersList = list
        .map((e) => ProfileData.fromJson(e as Map<String, dynamic>))
        .toList();
    return {'users': usersList, 'total': data['total'] as int? ?? 0};
  }

  Future<ProfileData> createUser(Map<String, dynamic> data) async {
    _guardWrite();
    final res = await apiClient.post('/admin/users', data: data);
    return ProfileData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ProfileData> updateUser(String id, Map<String, dynamic> data) async {
    _guardWrite();
    final res = await apiClient.put('/admin/users/$id', data: data);
    return ProfileData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    _guardWrite();
    await apiClient.delete('/admin/users/$id');
  }
}

final adminService = AdminService();
