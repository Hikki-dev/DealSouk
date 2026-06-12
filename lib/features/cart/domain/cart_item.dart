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
}
