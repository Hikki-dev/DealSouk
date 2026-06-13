class AdminSettings {
  final int tokenEarnRate;
  final int voucherThreshold;
  final int dailySubmissionCap;
  final int requestCostTokens;

  const AdminSettings({
    this.tokenEarnRate = 10,
    this.voucherThreshold = 500,
    this.dailySubmissionCap = 30,
    this.requestCostTokens = 10,
  });

  AdminSettings copyWith({
    int? tokenEarnRate,
    int? voucherThreshold,
    int? dailySubmissionCap,
    int? requestCostTokens,
  }) {
    return AdminSettings(
      tokenEarnRate: tokenEarnRate ?? this.tokenEarnRate,
      voucherThreshold: voucherThreshold ?? this.voucherThreshold,
      dailySubmissionCap: dailySubmissionCap ?? this.dailySubmissionCap,
      requestCostTokens: requestCostTokens ?? this.requestCostTokens,
    );
  }
}
