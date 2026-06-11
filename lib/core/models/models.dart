class Product {
  final String id;
  final String name;
  final String brand;
  final String packSize;
  final String category;
  final double lowestPrice;
  final String lowestPriceStore;
  final String updatedAtLabel;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.packSize,
    required this.category,
    required this.lowestPrice,
    required this.lowestPriceStore,
    required this.updatedAtLabel,
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
  final double xOffset; // Relative X coordinate (0.0 to 1.0) on our mock map
  final double yOffset; // Relative Y coordinate (0.0 to 1.0) on our mock map

  Store({
    required this.id,
    required this.name,
    required this.branch,
    required this.distance,
    required this.pricesCount,
    required this.freshness,
    required this.xOffset,
    required this.yOffset,
  });
}

class StoreProductPrice {
  final String storeId;
  final String storeName;
  final double price;
  final String updatedAtLabel;

  StoreProductPrice({
    required this.storeId,
    required this.storeName,
    required this.price,
    required this.updatedAtLabel,
  });
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class LeaderboardUser {
  final int rank;
  final String name;
  final int tokens;
  final bool isCurrentUser;

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.tokens,
    required this.isCurrentUser,
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
  });
}
