import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/requests/domain/price_request.dart';
import 'package:dealsouk/features/requests/data/requests_service.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';

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
      // Sync to the board so other shoppers see it instantly
      ref.read(priceRequestsProvider.notifier).fetchBoard();
    } catch (_) {}
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await requestsService.cancel(requestId);
      final reqIndex = state.indexWhere((r) => r.id == requestId);
      if (reqIndex >= 0) {
        final req = state[reqIndex];
        if (req.status == 'open') {
          // Refund the tokens
          ref.read(userTokensProvider.notifier).addTokens(req.requestRewardTokens);
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
