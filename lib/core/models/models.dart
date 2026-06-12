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
  });
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

  PriceRequest copyWith({
    String? status,
    String? timestampLabel,
  }) {
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

  StreakData copyWith({int? currentStreak, int? longestStreak, String? lastActivityLabel}) {
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

  AdminSettings copyWith({int? tokenEarnRate, int? voucherThreshold, int? dailySubmissionCap}) {
    return AdminSettings(
      tokenEarnRate: tokenEarnRate ?? this.tokenEarnRate,
      voucherThreshold: voucherThreshold ?? this.voucherThreshold,
      dailySubmissionCap: dailySubmissionCap ?? this.dailySubmissionCap,
    );
  }
}
