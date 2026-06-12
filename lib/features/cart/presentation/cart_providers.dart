import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/cart/domain/cart_item.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  Future<void> loadPersistedCart() async {
    final auth = ref.read(authProvider);
    if (auth.isGuest || auth.status != AuthStatus.authenticated) return;
    try {
      state = await profileService.getCart();
    } catch (_) {}
  }

  void _syncPersistedCart() {
    final auth = ref.read(authProvider);
    if (auth.isGuest || auth.status != AuthStatus.authenticated) return;
    unawaited(profileService.syncCart(state).catchError((_) {}));
  }

  void addToCart(Product product) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: existingItem.quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [
        ...state,
        CartItem(
          product: product,
          quantity: 1,
          priceAtAdd: product.lowestPrice,
        ),
      ];
    }
    _syncPersistedCart();
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _syncPersistedCart();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    _syncPersistedCart();
  }

  void clearCart() {
    state = [];
    _syncPersistedCart();
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);
