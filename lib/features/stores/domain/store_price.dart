import 'package:dealsouk/features/products/domain/product.dart';

class StorePrice {
  final Product product;
  final double priceAed;
  final String updatedAtLabel;
  final int hoursAgo;
  final bool verifiedWithPhoto;

  const StorePrice({
    required this.product,
    required this.priceAed,
    required this.updatedAtLabel,
    required this.hoursAgo,
    required this.verifiedWithPhoto,
  });

  factory StorePrice.fromJson(Map<String, dynamic> json) {
    final hoursAgo = json['hoursAgo'] as int? ?? 0;
    final productJson = json['product'] as Map<String, dynamic>;

    return StorePrice(
      product: Product.fromJson({
        ...productJson,
        'lowestPrice': json['priceAed'],
        'lowestPriceStore': json['storeName'],
        'hoursAgo': hoursAgo,
      }),
      priceAed: (json['priceAed'] as num).toDouble(),
      updatedAtLabel: hoursAgo < 1
          ? 'Updated just now'
          : hoursAgo < 24
          ? 'Updated ${hoursAgo}h ago'
          : 'Updated ${hoursAgo ~/ 24}d ago',
      hoursAgo: hoursAgo,
      verifiedWithPhoto: json['hasReceipt'] as bool? ?? false,
    );
  }
}
