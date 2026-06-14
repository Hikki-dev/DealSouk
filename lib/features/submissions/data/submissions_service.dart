import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/core/network/api_client.dart';
import 'package:dealsouk/core/offline/offline_submission_queue.dart';
import 'package:dio/dio.dart';

class SubmissionResult {
  final String id;
  final String status;
  final int tokensAwarded;

  /// True when the device was offline — submission was queued locally and
  /// will be sent automatically once connectivity is restored.
  final bool isQueued;

  const SubmissionResult({
    required this.id,
    required this.status,
    required this.tokensAwarded,
    this.isQueued = false,
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
  }) async {
    try {
      final res = await apiClient.post(
        '/submissions',
        data: {
          'productId': productId,
          'storeId': storeId,
          'priceAed': priceAed,
          'hasReceipt': hasReceipt,
          'receiptUrl': ?receiptUrl,
        },
      );
      final data = res.data as Map<String, dynamic>;
      return SubmissionResult(
        id: data['id'] as String,
        status: data['status'] as String,
        tokensAwarded: data['tokensAwarded'] as int? ?? 0,
      );
    } on DioException catch (e) {
      // No connectivity or server unreachable — queue for later.
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        await offlineSubmissionQueue.enqueue(
          PendingSubmission(
            productId: productId,
            storeId: storeId,
            priceAed: priceAed,
            hasReceipt: hasReceipt,
            receiptUrl: receiptUrl,
            queuedAtMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        return const SubmissionResult(
          id: 'offline',
          status: 'queued',
          tokensAwarded: 0,
          isQueued: true,
        );
      }
      rethrow;
    }
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
