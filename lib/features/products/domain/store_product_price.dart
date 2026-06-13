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
