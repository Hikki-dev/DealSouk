class Product {
  final String id;
  final String name;
  final String brand;
  final String packSize;
  final String category;
  final double lowestPrice;
  final String lowestPriceStore;
  final String updatedAtLabel;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.packSize,
    required this.category,
    required this.lowestPrice,
    required this.lowestPriceStore,
    required this.updatedAtLabel,
    this.imageUrl = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final hoursAgo = json['hoursAgo'] as int?;
    String updatedLabel;
    if (hoursAgo == null || json['lowestPrice'] == null) {
      updatedLabel = 'No recent price';
    } else if (hoursAgo < 1) {
      updatedLabel = 'Updated Just Now';
    } else if (hoursAgo < 24) {
      updatedLabel = 'Updated ${hoursAgo}h ago';
    } else {
      updatedLabel = 'Updated ${hoursAgo ~/ 24}d ago';
    }
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String? ?? '',
      packSize: json['packSize'] as String? ?? '',
      category: json['category'] as String,
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble() ?? 0.0,
      lowestPriceStore: json['lowestPriceStore'] as String? ?? '—',
      updatedAtLabel: updatedLabel,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Product copyWith({
    double? lowestPrice,
    String? lowestPriceStore,
    String? updatedAtLabel,
  }) {
    return Product(
      id: id,
      name: name,
      brand: brand,
      packSize: packSize,
      category: category,
      lowestPrice: lowestPrice ?? this.lowestPrice,
      lowestPriceStore: lowestPriceStore ?? this.lowestPriceStore,
      updatedAtLabel: updatedAtLabel ?? this.updatedAtLabel,
      imageUrl: imageUrl,
    );
  }
}

class Store {
  final String id;
  final String name;
  final String branch;
  final double distance;
  final int pricesCount;
  final String freshness;
  final double xOffset;
  final double yOffset;
  final int lastUpdatedHoursAgo;
  final double lat;
  final double lng;

  Store({
    required this.id,
    required this.name,
    required this.branch,
    required this.distance,
    required this.pricesCount,
    required this.freshness,
    required this.xOffset,
    required this.yOffset,
    this.lastUpdatedHoursAgo = 2,
    this.lat = 25.0771,
    this.lng = 55.1328,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    final hoursAgo =
        json['lastUpdatedHoursAgo'] as int? ??
        (json['lastUpdatedAt'] != null
            ? DateTime.now()
                  .difference(DateTime.parse(json['lastUpdatedAt'] as String))
                  .inHours
            : 48);
    String freshness;
    if (json['isStale'] == true) {
      freshness = 'Updated ${hoursAgo}h ago';
    } else if (hoursAgo < 1) {
      freshness = 'Fresh';
    } else if (hoursAgo < 6) {
      freshness = 'Fresh';
    } else {
      freshness = 'Updated ${hoursAgo}h ago';
    }
    return Store(
      id: json['id'] as String,
      name: json['chain'] as String,
      branch: json['branchName'] as String,
      distance: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      pricesCount: (json['activeSubmissionCount'] as int?) ?? 0,
      freshness: freshness,
      xOffset: 0.5,
      yOffset: 0.5,
      lastUpdatedHoursAgo: hoursAgo,
      lat: (json['lat'] as num?)?.toDouble() ?? 25.0771,
      lng: (json['lng'] as num?)?.toDouble() ?? 55.1328,
    );
  }
}

class StoreProductPrice {
  final String storeId;
  final String storeName;
  final double price;
  final String updatedAtLabel;
  final int submittedHoursAgo;

  StoreProductPrice({
    required this.storeId,
    required this.storeName,
    required this.price,
    required this.updatedAtLabel,
    this.submittedHoursAgo = 2,
  });

  factory StoreProductPrice.fromJson(Map<String, dynamic> json) {
    final h = json['hoursAgo'] as int? ?? 0;
    final label = h < 1
        ? 'Just Now'
        : h < 24
        ? '${h}h ago'
        : '${h ~/ 24}d ago';
    final store = json['store'] as Map<String, dynamic>;
    return StoreProductPrice(
      storeId: store['id'] as String,
      storeName: '${store['chain']} – ${store['branchName']}',
      price: (json['priceAed'] as num).toDouble(),
      updatedAtLabel: label,
      submittedHoursAgo: h,
    );
  }
}

class CartItem {
  final Product product;
  final int quantity;
  final double? priceAtAdd;

  CartItem({required this.product, required this.quantity, this.priceAtAdd});

  CartItem copyWith({Product? product, int? quantity, double? priceAtAdd}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      priceAtAdd: priceAtAdd ?? this.priceAtAdd,
    );
  }
}

class LeaderboardUser {
  final int rank;
  final String name;
  final int tokens;
  final bool isCurrentUser;
  final int streak;

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.tokens,
    required this.isCurrentUser,
    this.streak = 0,
  });

  factory LeaderboardUser.fromJson(
    Map<String, dynamic> json, {
    bool isCurrentUser = false,
  }) {
    return LeaderboardUser(
      rank: json['rank'] as int,
      name: json['displayName'] as String,
      tokens: (json['tokensThisMonth'] as int?) ?? 0,
      isCurrentUser: isCurrentUser,
    );
  }
}

class TokenTransaction {
  final String id;
  final int amount;
  final String title;
  final String timestampLabel;

  TokenTransaction({
    required this.id,
    required this.amount,
    required this.title,
    required this.timestampLabel,
  });

  factory TokenTransaction.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    String label = 'Recently';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes < 60) {
        label = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        label = '${diff.inHours}h ago';
      } else {
        label = '${diff.inDays}d ago';
      }
    }
    return TokenTransaction(
      id: json['id'] as String,
      amount: json['amount'] as int,
      title: json['reason'] as String,
      timestampLabel: label,
    );
  }
}

class AdminSubmission {
  final String id;
  final String productName;
  final String brand;
  final String storeName;
  final double price;
  final bool hasReceipt;
  final bool hasPhoto;
  final String promoType;
  final int tokensReward;
  final String timestampLabel;
  final String sourcerName;
  final String status; // 'pending', 'approved', 'rejected'

  AdminSubmission({
    required this.id,
    required this.productName,
    required this.brand,
    required this.storeName,
    required this.price,
    required this.hasReceipt,
    required this.hasPhoto,
    required this.promoType,
    required this.tokensReward,
    required this.timestampLabel,
    this.sourcerName = 'Hessa Al Maktoum',
    this.status = 'pending',
  });

  factory AdminSubmission.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['submittedAt'] as String? ?? '');
    String label = 'Recently';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes < 60) {
        label = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        label = '${diff.inHours}h ago';
      } else {
        label = '${diff.inDays}d ago';
      }
    }
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final store = json['store'] as Map<String, dynamic>? ?? {};
    return AdminSubmission(
      id: json['id'] as String,
      productName:
          product['name'] as String? ?? json['productName'] as String? ?? '',
      brand: product['brand'] as String? ?? '',
      storeName: '${store['chain'] ?? ''} ${store['branchName'] ?? ''}'.trim(),
      price: (json['priceAed'] as num?)?.toDouble() ?? 0.0,
      hasReceipt: json['hasReceipt'] as bool? ?? false,
      hasPhoto: false,
      promoType: 'Price Submission',
      tokensReward: json['tokensAwarded'] as int? ?? 0,
      timestampLabel: label,
      sourcerName: json['sourcerName'] as String? ?? 'Sourcer',
      status: json['status'] as String? ?? 'pending',
    );
  }

  AdminSubmission copyWith({
    String? productName,
    String? storeName,
    double? price,
    String? status,
  }) {
    return AdminSubmission(
      id: id,
      productName: productName ?? this.productName,
      brand: brand,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      hasReceipt: hasReceipt,
      hasPhoto: hasPhoto,
      promoType: promoType,
      tokensReward: tokensReward,
      timestampLabel: timestampLabel,
      sourcerName: sourcerName,
      status: status ?? this.status,
    );
  }
}

class PriceRequest {
  final String id;
  final String productName;
  final String storeName;
  final int tokensBounty;
  final String requesterName;
  final String status; // 'pending', 'fulfilled'
  final String timestampLabel;
  final double distance;

  PriceRequest({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.tokensBounty,
    required this.requesterName,
    this.status = 'pending',
    required this.timestampLabel,
    required this.distance,
  });

  factory PriceRequest.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    String label = 'Recently';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes < 60) {
        label = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        label = '${diff.inHours}h ago';
      } else {
        label = '${diff.inDays}d ago';
      }
    }
    return PriceRequest(
      id: json['id'] as String,
      productName: json['productName'] as String,
      storeName: json['storeName'] as String,
      tokensBounty: json['bountyTokens'] as int? ?? 0,
      requesterName: json['requesterName'] as String? ?? 'Sourcer',
      status: json['status'] as String? ?? 'open',
      timestampLabel: label,
      distance: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  PriceRequest copyWith({String? status, String? timestampLabel}) {
    return PriceRequest(
      id: id,
      productName: productName,
      storeName: storeName,
      tokensBounty: tokensBounty,
      requesterName: requesterName,
      status: status ?? this.status,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      distance: distance,
    );
  }
}

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final String lastActivityLabel;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityLabel,
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastActivityLabel,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityLabel: lastActivityLabel ?? this.lastActivityLabel,
    );
  }
}

class UserBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool unlocked;

  const UserBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.unlocked,
  });

  UserBadge copyWith({bool? unlocked}) {
    return UserBadge(
      id: id,
      name: name,
      emoji: emoji,
      description: description,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}

class DailyChallenge {
  final String id;
  final String description;
  final String targetStore;
  final int targetCount;
  final int bonusTokens;
  final int progressCount;
  final bool completed;

  const DailyChallenge({
    required this.id,
    required this.description,
    required this.targetStore,
    required this.targetCount,
    required this.bonusTokens,
    this.progressCount = 0,
    this.completed = false,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    final progress = json['userProgress'] as Map<String, dynamic>?;
    return DailyChallenge(
      id: json['id'] as String,
      description:
          json['description'] as String? ??
          json['title'] as String? ??
          'Submit fresh prices today',
      targetStore: json['chainTarget'] as String? ?? 'Any',
      targetCount: json['targetCount'] as int? ?? 3,
      bonusTokens: json['bonusTokens'] as int? ?? 30,
      progressCount: progress?['progress'] as int? ?? 0,
      completed: progress?['completed'] as bool? ?? false,
    );
  }

  DailyChallenge copyWith({int? progressCount, bool? completed}) {
    return DailyChallenge(
      id: id,
      description: description,
      targetStore: targetStore,
      targetCount: targetCount,
      bonusTokens: bonusTokens,
      progressCount: progressCount ?? this.progressCount,
      completed: completed ?? this.completed,
    );
  }
}

class AdminSettings {
  final int tokenEarnRate;
  final int voucherThreshold;
  final int dailySubmissionCap;

  const AdminSettings({
    this.tokenEarnRate = 10,
    this.voucherThreshold = 500,
    this.dailySubmissionCap = 30,
  });

  AdminSettings copyWith({
    int? tokenEarnRate,
    int? voucherThreshold,
    int? dailySubmissionCap,
  }) {
    return AdminSettings(
      tokenEarnRate: tokenEarnRate ?? this.tokenEarnRate,
      voucherThreshold: voucherThreshold ?? this.voucherThreshold,
      dailySubmissionCap: dailySubmissionCap ?? this.dailySubmissionCap,
    );
  }
}
