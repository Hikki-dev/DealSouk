import '../models/models.dart';
import 'api_client.dart';

class ProfileData {
  final String id;
  final String displayName;
  final String? homeArea;
  final String preferredLocale;
  final int tokenBalance;
  final double accuracyRating;
  final bool isAdmin;
  final int totalSubmissions;
  final int approvedSubmissions;

  const ProfileData({
    required this.id,
    required this.displayName,
    this.homeArea,
    required this.preferredLocale,
    required this.tokenBalance,
    required this.accuracyRating,
    required this.isAdmin,
    required this.totalSubmissions,
    required this.approvedSubmissions,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    homeArea: json['homeArea'] as String?,
    preferredLocale: json['preferredLocale'] as String? ?? 'en',
    tokenBalance: json['tokenBalance'] as int? ?? 0,
    accuracyRating: (json['accuracyRating'] as num?)?.toDouble() ?? 100.0,
    isAdmin: json['isAdmin'] as bool? ?? false,
    totalSubmissions: json['totalSubmissions'] as int? ?? 0,
    approvedSubmissions: json['approvedSubmissions'] as int? ?? 0,
  );
}

class ProfileService {
  Future<ProfileData> getMyProfile() async {
    final res = await apiClient.get('/profile/me');
    return ProfileData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TokenTransaction>> getTransactions({int page = 0}) async {
    final res = await apiClient.get(
      '/profile/me/transactions',
      params: {'page': page},
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => TokenTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CartItem>> getCart() async {
    final res = await apiClient.get('/profile/me/cart');
    final list = res.data as List<dynamic>;
    return list.map((e) {
      final item = e as Map<String, dynamic>;
      final productJson = item['product'] as Map<String, dynamic>;
      final product = Product.fromJson({
        ...productJson,
        'lowestPrice': productJson['lowestPrice'] ?? 0,
        'lowestPriceStore': productJson['lowestPriceStore'] ?? '—',
      });
      return CartItem(
        product: product,
        quantity: item['quantity'] as int? ?? 1,
        priceAtAdd: product.lowestPrice,
      );
    }).toList();
  }

  Future<void> syncCart(List<CartItem> items) async {
    await apiClient.put(
      '/profile/me/cart',
      data: {
        'items': items
            .map(
              (item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
      },
    );
  }

  Future<void> updateProfile({
    String? displayName,
    String? homeArea,
    String? preferredLocale,
  }) async {
    await apiClient.patch(
      '/profile/me',
      data: {
        'displayName': ?displayName,
        'homeArea': ?homeArea,
        'preferredLocale': ?preferredLocale,
      },
    );
  }
}

final profileService = ProfileService();
