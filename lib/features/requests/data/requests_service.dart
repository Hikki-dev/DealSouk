import 'package:dealsouk/features/requests/domain/price_request.dart';
import 'package:dealsouk/core/network/api_client.dart';

class RequestsService {
  Future<List<PriceRequest>> getBoard() async {
    final res = await apiClient.get('/requests/board');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => PriceRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PriceRequest> create({
    required String productName,
    required String storeName,
    required int requestCostTokens,
  }) async {
    final res = await apiClient.post(
      '/requests',
      data: {
        'productName': productName,
        'storeName': storeName,
        'bountyTokens': requestCostTokens,
      },
    );
    return PriceRequest.fromJson(res.data as Map<String, dynamic>);
  }

  Future<int> fulfill(String requestId) async {
    final res = await apiClient.post('/requests/$requestId/fulfill');
    final data = res.data as Map<String, dynamic>;
    return data['tokensEarned'] as int? ?? 0;
  }
}

final requestsService = RequestsService();
