import 'package:dealsouk/features/products/domain/product.dart';

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

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'priceAtAdd': priceAtAdd,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(
      Map<String, dynamic>.from(json['product'] as Map),
    ),
    quantity: json['quantity'] as int? ?? 1,
    priceAtAdd: (json['priceAtAdd'] as num?)?.toDouble(),
  );
}
