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
