import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/cart/domain/cart_item.dart';
import 'package:dealsouk/features/tokens/domain/token_transaction.dart';
import 'package:dealsouk/features/tokens/domain/user_badge.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/core/network/api_client.dart';

class ProfileData {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? homeArea;
  final String preferredLocale;
  final int tokenBalance;
  final double accuracyRating;
  final bool isAdmin;
  final int totalSubmissions;
  final int approvedSubmissions;
  final int currentStreak;
  final int longestStreak;
  final List<UserBadge> badges;

  const ProfileData({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.homeArea,
    required this.preferredLocale,
    required this.tokenBalance,
    required this.accuracyRating,
    required this.isAdmin,
    required this.totalSubmissions,
    required this.approvedSubmissions,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badges = const [],
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'] as List<dynamic>? ?? const [];
    return ProfileData(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      homeArea: json['homeArea'] as String?,
      preferredLocale: json['preferredLocale'] as String? ?? 'en',
      tokenBalance: json['tokenBalance'] as int? ?? 0,
      accuracyRating: (json['accuracyRating'] as num?)?.toDouble() ?? 100.0,
      isAdmin: json['isAdmin'] as bool? ?? false,
      totalSubmissions: json['totalSubmissions'] as int? ?? 0,
      approvedSubmissions: json['approvedSubmissions'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      badges: rawBadges.map((entry) {
        final badge = entry as Map<String, dynamic>;
        return UserBadge(
          id: badge['id'] as String? ?? '',
          name: badge['name'] as String? ?? '',
          emoji: badge['emoji'] as String? ?? '',
          description: badge['description'] as String? ?? '',
          unlocked: true,
          unlockedAtLabel: badge['unlockedAt'] as String?,
        );
      }).toList(),
    );
  }
}

class UserVoucher {
  final String id;
  final String status;
  final int denominationAed;
  final String supermarket;
  final String? voucherCode;
  final DateTime requestedAt;
  final DateTime? deliveredAt;

  const UserVoucher({
    required this.id,
    required this.status,
    required this.denominationAed,
    required this.supermarket,
    required this.voucherCode,
    required this.requestedAt,
    required this.deliveredAt,
  });

  factory UserVoucher.fromJson(Map<String, dynamic> json) => UserVoucher(
    id: json['id'] as String,
    status: json['status'] as String? ?? 'pending',
    denominationAed: json['denominationAed'] as int? ?? 50,
    supermarket: json['supermarket'] as String? ?? 'Partner supermarket',
    voucherCode: json['voucherCode'] as String?,
    requestedAt:
        DateTime.tryParse(json['requestedAt'] as String? ?? '') ??
        DateTime.now(),
    deliveredAt: DateTime.tryParse(json['deliveredAt'] as String? ?? ''),
  );
}

class ProfileService {
  Future<ProfileData> getMyProfile() async {
    final res = await apiClient.get('/profile/me');
    return ProfileData.fromJson(res.data as Map<String, dynamic>);
  }

  /// The current user's own submissions (FR-30 "My Submissions") straight from
  /// the DB — independent of the admin moderation queue. AdminSubmission already
  /// parses this exact shape (product/store/priceAed/status/tokensAwarded).
  Future<List<AdminSubmission>> getMySubmissions() async {
    final res = await apiClient.get('/profile/me/submissions');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AdminSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<List<UserVoucher>> getVouchers() async {
    final res = await apiClient.get('/profile/me/vouchers');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => UserVoucher.fromJson(e as Map<String, dynamic>))
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
    String? avatarUrl,
    String? homeArea,
    String? preferredLocale,
  }) async {
    await apiClient.patch(
      '/profile/me',
      data: {
        'displayName': ?displayName,
        'avatarUrl': ?avatarUrl,
        'homeArea': ?homeArea,
        'preferredLocale': ?preferredLocale,
      },
    );
  }
}

final profileService = ProfileService();
