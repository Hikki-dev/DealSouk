import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/core/offline/connectivity_service.dart';
import 'package:dealsouk/core/offline/offline_queue.dart';
import 'package:dealsouk/features/submissions/data/submissions_service.dart';
import 'package:dealsouk/features/requests/data/requests_service.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';

/// Owns the offline outbox (NFR-22): queues submissions/price-requests made
/// while offline and replays them in order when connectivity returns. The
/// state value is the number of pending ops, used to drive the offline banner.
class SyncController extends Notifier<int> {
  bool _syncing = false;

  @override
  int build() {
    // Auto-drain whenever we come back online.
    ref.listen(isOnlineProvider, (prev, next) {
      if (next == true) {
        // ignore: discarded_futures
        syncNow();
      }
    });
    // ignore: discarded_futures
    _refreshCount();
    return 0;
  }

  Future<void> _refreshCount() async {
    state = await offlineQueue.count();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> enqueueSubmission({
    required String productId,
    required String storeId,
    required double priceAed,
    bool hasReceipt = false,
    String? receiptUrl,
  }) async {
    await offlineQueue.enqueue(
      PendingOp(
        id: _newId(),
        type: 'submission',
        payload: {
          'productId': productId,
          'storeId': storeId,
          'priceAed': priceAed,
          'hasReceipt': hasReceipt,
          'receiptUrl': ?receiptUrl,
        },
        createdAt: DateTime.now(),
      ),
    );
    await _refreshCount();
  }

  Future<void> enqueueRequest({
    required String productName,
    required String storeName,
    required int requestCostTokens,
  }) async {
    await offlineQueue.enqueue(
      PendingOp(
        id: _newId(),
        type: 'request',
        payload: {
          'productName': productName,
          'storeName': storeName,
          'requestCostTokens': requestCostTokens,
        },
        createdAt: DateTime.now(),
      ),
    );
    await _refreshCount();
  }

  /// Replays every queued op in order. Stops on the first failure (we're likely
  /// offline again or the server is down) and retries on the next reconnect.
  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final ops = await offlineQueue.all();
      if (ops.isEmpty) return;

      var processedAny = false;
      for (final op in ops) {
        try {
          if (op.type == 'submission') {
            await submissionsService.create(
              productId: op.payload['productId'] as String,
              storeId: op.payload['storeId'] as String,
              priceAed: (op.payload['priceAed'] as num).toDouble(),
              hasReceipt: op.payload['hasReceipt'] as bool? ?? false,
              receiptUrl: op.payload['receiptUrl'] as String?,
            );
          } else if (op.type == 'request') {
            await requestsService.create(
              productName: op.payload['productName'] as String,
              storeName: op.payload['storeName'] as String,
              requestCostTokens: op.payload['requestCostTokens'] as int? ?? 0,
            );
          }
          await offlineQueue.remove(op.id);
          processedAny = true;
        } catch (_) {
          // Still offline / transient server error — keep this op and retry
          // on the next reconnect.
          break;
        }
      }

      await _refreshCount();

      if (processedAny) {
        // Pull fresh server state into the views that the replayed ops affect.
        ref.read(productsProvider.notifier).fetch();
        ref.read(priceRequestsProvider.notifier).fetchBoard();
        ref.read(myRequestsProvider.notifier).fetchMyRequests();
      }
    } finally {
      _syncing = false;
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, int>(
  SyncController.new,
);
