class TokenLedgerEntry {
  final int amount;
  final String reason;

  const TokenLedgerEntry({required this.amount, required this.reason});
}

class TokenAccount {
  final int balance;
  final List<TokenLedgerEntry> ledger;

  const TokenAccount({required this.balance, this.ledger = const []});

  TokenAccount apply(int amount, String reason) {
    return TokenAccount(
      balance: balance + amount,
      ledger: [
        TokenLedgerEntry(amount: amount, reason: reason),
        ...ledger,
      ],
    );
  }
}

TokenAccount createPriceRequest({
  required TokenAccount account,
  required int requestCostTokens,
  required String productName,
}) {
  if (requestCostTokens < 0) {
    throw ArgumentError.value(requestCostTokens, 'requestCostTokens');
  }
  if (account.balance < requestCostTokens) {
    throw StateError('Insufficient token balance');
  }
  return account.apply(-requestCostTokens, 'Price request: $productName');
}

TokenAccount refundExpiredRequest({
  required TokenAccount account,
  required int requestCostTokens,
  required String productName,
}) {
  return account.apply(requestCostTokens, 'Refunded request: $productName');
}

TokenAccount rewardApprovedSubmission({
  required TokenAccount account,
  required int rewardTokens,
  required String productName,
}) {
  if (rewardTokens < 0) {
    throw ArgumentError.value(rewardTokens, 'rewardTokens');
  }
  return account.apply(rewardTokens, 'Approved submission: $productName');
}

bool hasReachedDailySubmissionCap({
  required int approvedOrPendingToday,
  required int dailySubmissionCap,
}) {
  return approvedOrPendingToday >= dailySubmissionCap;
}
