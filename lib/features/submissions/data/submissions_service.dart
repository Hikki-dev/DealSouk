import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/core/network/api_client.dart';

class SubmissionResult {
  final String id;
  final String status;
  final int tokensAwarded;

  const SubmissionResult({
    required this.id,
    required this.status,
    required this.tokensAwarded,
  });
}

class SubmissionsService {
  Future<List<AdminSubmission>> getFeed({int page = 0}) async {
    final res = await apiClient.get(
      '/submissions/feed',
      params: {'page': page},
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AdminSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubmissionResult> create({
    required String productId,
    required String storeId,
    required double priceAed,
    bool hasReceipt = false,
    String? receiptUrl,
    String? priceLabelUrl,
  }) async {
    // Offline queueing is owned by SyncController (sync_service.dart). This
    // method just performs the call and throws on failure, so the replay loop
    // can decide to retry (transient) or drop (permanent rejection).
    final res = await apiClient.post(
      '/submissions',
      data: {
        'productId': productId,
        'storeId': storeId,
        'priceAed': priceAed,
        'hasReceipt': hasReceipt,
        'receiptUrl': ?receiptUrl,
        'priceLabelUrl': ?priceLabelUrl,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return SubmissionResult(
      id: data['id'] as String,
      status: data['status'] as String,
      tokensAwarded: data['tokensAwarded'] as int? ?? 0,
    );
  }

  Future<int> estimateTokens({
    required String productId,
    required String storeId,
    bool hasReceipt = false,
  }) async {
    final res = await apiClient.get(
      '/submissions/estimate',
      params: {
        'productId': productId,
        'storeId': storeId,
        'hasReceipt': hasReceipt.toString(),
      },
    );
    final data = res.data as Map<String, dynamic>;
    return data['estimatedTokens'] as int? ?? 0;
  }

  Future<void> flag(String submissionId, String reason) async {
    await apiClient.post(
      '/submissions/$submissionId/flag',
      data: {'reason': reason},
    );
  }
}

final submissionsService = SubmissionsService();
