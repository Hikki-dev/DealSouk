import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/domain/product_price_history.dart';
import 'package:dealsouk/features/products/domain/store_product_price.dart';
import 'package:dealsouk/core/network/api_client.dart';

class ProductsService {
  Future<List<Product>> search({String query = '', String? category}) async {
    final res = await apiClient.get(
      '/products/search',
      params: {if (query.isNotEmpty) 'q': query, 'category': ?category},
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StoreProductPrice>> getPrices(String productId) async {
    final res = await apiClient.get('/products/$productId/prices');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => StoreProductPrice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductPriceHistory>> getHistory(String productId) async {
    final res = await apiClient.get('/products/$productId/history');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ProductPriceHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final productsService = ProductsService();
