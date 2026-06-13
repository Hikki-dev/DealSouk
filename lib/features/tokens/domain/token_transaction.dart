class TokenTransaction {
  final String id;
  final int amount;
  final String title;
  final String timestampLabel;

  TokenTransaction({
    required this.id,
    required this.amount,
    required this.title,
    required this.timestampLabel,
  });

  factory TokenTransaction.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
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
    return TokenTransaction(
      id: json['id'] as String,
      amount: json['amount'] as int,
      title: json['reason'] as String,
      timestampLabel: label,
    );
  }
}
