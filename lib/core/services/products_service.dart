import '../models/models.dart';
import 'api_client.dart';

class ProductsService {
  Future<List<Product>> search({String query = '', String? category}) async {
    final res = await apiClient.get(
      '/products/search',
      params: {
        if (query.isNotEmpty) 'q': query,
        'category': ?category,
      },
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
}

final productsService = ProductsService();
