class ProductPriceHistory {
  final String id;
  final double priceAed;
  final DateTime submittedAt;
  final String storeName;

  const ProductPriceHistory({
    required this.id,
    required this.priceAed,
    required this.submittedAt,
    required this.storeName,
  });

  factory ProductPriceHistory.fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>? ?? {};
    return ProductPriceHistory(
      id: json['id'] as String,
      priceAed: (json['priceAed'] as num?)?.toDouble() ?? 0,
      submittedAt:
          DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      storeName: '${store['chain'] ?? ''} ${store['branchName'] ?? ''}'.trim(),
    );
  }
}
