class VoucherRequest {
  final String id;
  final String status;
  final int thresholdTokens;
  final int tokenCost;
  final int denominationAed;
  final String supermarket;
  final String? voucherCode;
  final String? adminNote;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String userName;
  final String? userHomeArea;
  final int userTokenBalance;

  const VoucherRequest({
    required this.id,
    required this.status,
    required this.thresholdTokens,
    required this.tokenCost,
    required this.denominationAed,
    required this.supermarket,
    required this.voucherCode,
    required this.adminNote,
    required this.requestedAt,
    required this.reviewedAt,
    required this.userName,
    required this.userHomeArea,
    required this.userTokenBalance,
  });

  factory VoucherRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return VoucherRequest(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      thresholdTokens: json['thresholdTokens'] as int? ?? 500,
      tokenCost: json['tokenCost'] as int? ?? 500,
      denominationAed: json['denominationAed'] as int? ?? 50,
      supermarket: json['supermarket'] as String? ?? 'Partner supermarket',
      voucherCode: json['voucherCode'] as String?,
      adminNote: json['adminNote'] as String?,
      requestedAt:
          DateTime.tryParse(json['requestedAt'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      userName: user['displayName'] as String? ?? 'Shopper',
      userHomeArea: user['homeArea'] as String?,
      userTokenBalance: user['tokenBalance'] as int? ?? 0,
    );
  }
}
