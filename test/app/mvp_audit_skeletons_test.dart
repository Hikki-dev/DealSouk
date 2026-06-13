import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/tokens/domain/token_rules.dart';
import 'package:dealsouk/features/submissions/domain/submission_moderation.dart';
import 'package:dealsouk/features/cart/domain/cart_item.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/app/route_guard.dart';

void main() {
  group('MVP Audit Unit Tests', () {
    // 1. Token Engine
    test('Token Engine - calculated estimate matches PRD bounds', () {
      final account = const TokenAccount(balance: 100);
      final updated = rewardApprovedSubmission(
        account: account,
        rewardTokens: 50,
        productName: 'Bread',
      );
      expect(updated.balance, 150);
      expect(updated.ledger.first.amount, 50);
      expect(updated.ledger.first.reason, 'Approved submission: Bread');
    });

    // 2. Submission Cap
    test('Submission Cap - user cannot exceed daily submission cap', () {
      expect(
        hasReachedDailySubmissionCap(
          approvedOrPendingToday: 29,
          dailySubmissionCap: 30,
        ),
        isFalse,
      );
      expect(
        hasReachedDailySubmissionCap(
          approvedOrPendingToday: 30,
          dailySubmissionCap: 30,
        ),
        isTrue,
      );
    });

    // 3. Flag Auto-Hide
    test('Flag Auto-Hide - submission is hidden after threshold flags', () {
      var state = const FlagState();
      expect(state.hidden, isFalse);

      state = addUniqueFlag(state, 'user_a');
      expect(state.hidden, isFalse);

      state = addUniqueFlag(state, 'user_b');
      expect(state.hidden, isFalse);

      state = addUniqueFlag(state, 'user_c');
      expect(state.hidden, isTrue); // Auto-hides at 3 unique flags
    });

    // 4. Request Refund
    test('Request Refund - bounty tokens are returned upon expiration', () {
      final account = const TokenAccount(balance: 100);
      final updated = refundExpiredRequest(
        account: account,
        requestCostTokens: 10,
        productName: 'Milk',
      );
      expect(updated.balance, 110);
      expect(updated.ledger.first.amount, 10);
      expect(updated.ledger.first.reason, 'Refunded request: Milk');
    });

    // 5. Cart Sync
    test('Cart Sync - quantity boundaries and cart item copies', () {
      final product = Product(
        id: 'p1',
        name: 'Water',
        brand: 'Masafi',
        packSize: '6x1.5L',
        category: 'Beverages',
        lowestPrice: 6.50,
        lowestPriceStore: 'Carrefour',
        updatedAtLabel: 'Updated Just Now',
      );
      final item = CartItem(product: product, quantity: 2);
      expect(item.quantity, 2);

      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.product.id, 'p1');
    });

    // 6. Auth Guard
    test('Auth Guard - unauthenticated users are redirected to welcome', () {
      final redirect = resolveRouteRedirect(
        matchedLocation: '/profile',
        isAuthUnknown: false,
        isUnauthenticated: true,
        isGuest: false,
        isAdmin: false,
      );
      expect(redirect, '/welcome');
    });

    // 7. Admin Guard
    test('Admin Guard - non-admin users cannot access admin paths', () {
      final redirect = resolveRouteRedirect(
        matchedLocation: '/admin',
        isAuthUnknown: false,
        isUnauthenticated: false,
        isGuest: false,
        isAdmin: false,
      );
      expect(redirect, '/unauthorized');
    });
  });
}
