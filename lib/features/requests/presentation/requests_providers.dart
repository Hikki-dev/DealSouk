import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/requests/domain/price_request.dart';
import 'package:dealsouk/features/requests/data/requests_service.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/core/offline/connectivity_service.dart';
import 'package:dealsouk/core/offline/sync_service.dart';

class PriceRequestsNotifier extends Notifier<List<PriceRequest>> {
  @override
  List<PriceRequest> build() => [];

  Future<void> fetchBoard() async {
    try {
      final results = await requestsService.getBoard();
      state = results;
    } catch (_) {}
  }

  Future<void> addPriceRequest({
    required String productName,
    required String storeName,
    required int requestCostTokens,
    required String requesterName,
  }) async {
    try {
      final created = await requestsService.create(
        productName: productName,
        storeName: storeName,
        requestCostTokens: requestCostTokens,
      );
      if (requestCostTokens > 0) {
        ref.read(userTokensProvider.notifier).deductTokens(requestCostTokens);
        ref
            .read(userTransactionsProvider.notifier)
            .addTransaction(
              -requestCostTokens,
              'Requested price check: $productName at $storeName',
            );
      }
      state = [created, ...state];
    } catch (_) {}
  }

  Future<void> fulfillPriceRequest(String requestId) async {
    try {
      final earned = await requestsService.fulfill(requestId);
      if (earned > 0) {
        ref.read(userTokensProvider.notifier).addTokens(earned);
        ref
            .read(userTransactionsProvider.notifier)
            .addTransaction(earned, 'Fulfilled a price request');
      }
      state = state.map((req) {
        if (req.id == requestId) {
          return req.copyWith(
            status: 'fulfilled',
            timestampLabel: 'Fulfilled Just Now',
          );
        }
        return req;
      }).toList();
    } catch (_) {}
  }

  void markPriceRequestFulfilled(String requestId) {
    state = state.map((req) {
      if (req.id == requestId) {
        return req.copyWith(
          status: 'fulfilled',
          timestampLabel: 'Fulfilled Just Now',
        );
      }
      return req;
    }).toList();
  }

  void refundPriceRequest(String requestId) {
    final reqIndex = state.indexWhere((r) => r.id == requestId);
    if (reqIndex >= 0) {
      final req = state[reqIndex];
      if (req.requestRewardTokens > 0) {
        ref
            .read(userTokensProvider.notifier)
            .addTokens(req.requestRewardTokens);
        ref
            .read(userTransactionsProvider.notifier)
            .addTransaction(
              req.requestRewardTokens,
              'Refunded request: ${req.productName} check',
            );
      }
      state = state.where((r) => r.id != requestId).toList();
    }
  }
}

final priceRequestsProvider =
    NotifierProvider<PriceRequestsNotifier, List<PriceRequest>>(
      PriceRequestsNotifier.new,
    );

class MyRequestsNotifier extends Notifier<List<PriceRequest>> {
  /// Set when the last addPriceRequest was rejected (e.g. not enough tokens) so
  /// the UI can show a message instead of silently doing nothing.
  String? lastError;

  @override
  List<PriceRequest> build() => [];

  Future<void> fetchMyRequests() async {
    try {
      final results = await requestsService.getMyRequests();
      state = results;
    } catch (_) {}
  }

  Future<void> addPriceRequest({
    required String productName,
    required String storeName,
    required int requestCostTokens,
  }) async {
    // Optimistically reflect the token cost regardless of connectivity.
    void applyTokenCost() {
      if (requestCostTokens > 0) {
        ref.read(userTokensProvider.notifier).deductTokens(requestCostTokens);
        ref
            .read(userTransactionsProvider.notifier)
            .addTransaction(
              -requestCostTokens,
              'Requested price check: $productName at $storeName',
            );
      }
    }

    // Affordability guard: the backend rejects a request you can't pay for, so
    // don't attempt/queue/deduct it at all (this is what caused the stuck
    // "1 change waiting to sync" banner and the negative balance).
    if (requestCostTokens > 0 &&
        ref.read(userTokensProvider) < requestCostTokens) {
      lastError = 'Not enough tokens — submit a few prices to earn some first.';
      return;
    }
    lastError = null;

    // Offline (NFR-22): queue the request and replay it on reconnect. It will
    // appear on the board once synced; the token cost is shown immediately.
    if (!await isCurrentlyOnline()) {
      await ref
          .read(syncControllerProvider.notifier)
          .enqueueRequest(
            productName: productName,
            storeName: storeName,
            requestCostTokens: requestCostTokens,
          );
      applyTokenCost();
      return;
    }

    try {
      final created = await requestsService.create(
        productName: productName,
        storeName: storeName,
        requestCostTokens: requestCostTokens,
      );
      applyTokenCost();
      state = [created, ...state];
      // Sync to the board so other shoppers see it instantly
      ref.read(priceRequestsProvider.notifier).fetchBoard();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code != null && code >= 400 && code < 500) {
        // Server permanently rejected it (e.g. insufficient tokens, bad data).
        // Nothing to retry — do NOT queue or deduct.
        lastError = (e.response?.data is Map)
            ? (e.response?.data['error']?.toString() ?? 'Request rejected')
            : 'Request rejected';
        return;
      }
      // Genuine network/timeout/5xx — queue it so it isn't lost.
      await ref
          .read(syncControllerProvider.notifier)
          .enqueueRequest(
            productName: productName,
            storeName: storeName,
            requestCostTokens: requestCostTokens,
          );
      applyTokenCost();
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await requestsService.cancel(requestId);
      final reqIndex = state.indexWhere((r) => r.id == requestId);
      if (reqIndex >= 0) {
        final req = state[reqIndex];
        if (req.status == 'open') {
          // Refund the tokens
          ref
              .read(userTokensProvider.notifier)
              .addTokens(req.requestRewardTokens);
          ref
              .read(userTransactionsProvider.notifier)
              .addTransaction(
                req.requestRewardTokens,
                'Refund: cancelled request for ${req.productName}',
              );
        }
      }
      // Remove it or mark cancelled
      state = state.where((r) => r.id != requestId).toList();
      // Sync back to the board
      ref.read(priceRequestsProvider.notifier).fetchBoard();
    } catch (_) {}
  }
}

final myRequestsProvider =
    NotifierProvider<MyRequestsNotifier, List<PriceRequest>>(
      MyRequestsNotifier.new,
    );
