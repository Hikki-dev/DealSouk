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
  final String barcode;

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
    this.barcode = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Round-trip path: a cached product already carries its display label.
    if (json['updatedAtLabel'] != null && json['hoursAgo'] == null) {
      return Product(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String? ?? '',
        packSize: json['packSize'] as String? ?? '',
        category: json['category'] as String,
        lowestPrice: (json['lowestPrice'] as num?)?.toDouble() ?? 0.0,
        lowestPriceStore: json['lowestPriceStore'] as String? ?? '—',
        updatedAtLabel: json['updatedAtLabel'] as String,
        imageUrl: json['imageUrl'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
      );
    }
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
      barcode: json['barcode'] as String? ?? '',
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
      barcode: barcode,
    );
  }

  /// Serialises every field (including the resolved label) so it can be cached
  /// locally and rebuilt offline via [Product.fromJson].
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'packSize': packSize,
    'category': category,
    'lowestPrice': lowestPrice,
    'lowestPriceStore': lowestPriceStore,
    'updatedAtLabel': updatedAtLabel,
    'imageUrl': imageUrl,
    'barcode': barcode,
  };
}
