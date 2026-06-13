import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/tokens/domain/token_rules.dart';

void main() {
  test('token deduction when creating request', () {
    // Protects PRD request-board rule: creating a price request spends the
    // configured bounty/cost tokens immediately.
    final account = createPriceRequest(
      account: const TokenAccount(balance: 100),
      requestCostTokens: 15,
      productName: 'Al Rawabi Milk',
    );

    expect(account.balance, 85);
    expect(account.ledger.single.amount, -15);
  });

  test('token refund when request expires', () {
    // Protects PRD 48-hour expiry rule: unfulfilled requests refund the
    // requester instead of permanently burning tokens.
    final afterCreate = createPriceRequest(
      account: const TokenAccount(balance: 100),
      requestCostTokens: 20,
      productName: 'Basmati Rice',
    );

    final refunded = refundExpiredRequest(
      account: afterCreate,
      requestCostTokens: 20,
      productName: 'Basmati Rice',
    );

    expect(refunded.balance, 100);
    expect(refunded.ledger.first.amount, 20);
  });

  test('token reward after approved submission', () {
    // Protects PRD token economy rule: approved price submissions earn tokens
    // only after moderation approval.
    final rewarded = rewardApprovedSubmission(
      account: const TokenAccount(balance: 40),
      rewardTokens: 12,
      productName: 'Eggs',
    );

    expect(rewarded.balance, 52);
    expect(rewarded.ledger.single.reason, contains('Approved submission'));
  });

  test('daily submission cap blocks additional submissions', () {
    // Protects PRD daily cap rule: users cannot exceed the configured daily
    // price-submission limit.
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
}
