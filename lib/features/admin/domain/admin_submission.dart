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
  final String sourcerId;
  final String sourcerName;
  final double sourcerAccuracyRating;
  final String status; // 'pending', 'approved', 'rejected'
  final String productImageUrl;
  final String priceLabelUrl;

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
    this.sourcerId = '',
    this.sourcerName = 'Hessa Al Maktoum',
    this.sourcerAccuracyRating = 100,
    this.status = 'pending',
    this.productImageUrl = '',
    this.priceLabelUrl = '',
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
    final sourcer = json['sourcer'] as Map<String, dynamic>? ?? {};
    return AdminSubmission(
      id: json['id'] as String,
      productName:
          product['name'] as String? ?? json['productName'] as String? ?? '',
      brand: product['brand'] as String? ?? '',
      productImageUrl: product['imageUrl'] as String? ?? '',
      priceLabelUrl: json['priceLabelUrl'] as String? ?? '',
      storeName: '${store['chain'] ?? ''} ${store['branchName'] ?? ''}'.trim(),
      price: (json['priceAed'] as num?)?.toDouble() ?? 0.0,
      hasReceipt: json['hasReceipt'] as bool? ?? false,
      hasPhoto: (json['priceLabelUrl'] as String?)?.isNotEmpty ?? false,
      promoType: 'Price Submission',
      tokensReward: json['tokensAwarded'] as int? ?? 0,
      timestampLabel: label,
      sourcerId: sourcer['id'] as String? ?? '',
      sourcerName:
          sourcer['displayName'] as String? ??
          json['sourcerName'] as String? ??
          'Sourcer',
      sourcerAccuracyRating:
          (sourcer['accuracyRating'] as num?)?.toDouble() ?? 100,
      status: json['status'] as String? ?? 'pending',
    );
  }

  AdminSubmission copyWith({
    String? productName,
    String? storeName,
    double? price,
    String? status,
    String? productImageUrl,
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
      sourcerId: sourcerId,
      sourcerName: sourcerName,
      sourcerAccuracyRating: sourcerAccuracyRating,
      status: status ?? this.status,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      priceLabelUrl: priceLabelUrl,
    );
  }
}
