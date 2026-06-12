class PriceRequest {
  final String id;
  final String productName;
  final String storeName;
  final int requestRewardTokens;
  final String requesterName;
  final String status; // 'pending', 'fulfilled'
  final String timestampLabel;
  final double distance;

  PriceRequest({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.requestRewardTokens,
    required this.requesterName,
    this.status = 'pending',
    required this.timestampLabel,
    required this.distance,
  });

  factory PriceRequest.fromJson(Map<String, dynamic> json) {
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
    return PriceRequest(
      id: json['id'] as String,
      productName: json['productName'] as String,
      storeName: json['storeName'] as String,
      requestRewardTokens: json['bountyTokens'] as int? ?? 0,
      requesterName: json['requesterName'] as String? ?? 'Sourcer',
      status: json['status'] as String? ?? 'open',
      timestampLabel: label,
      distance: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  PriceRequest copyWith({String? status, String? timestampLabel}) {
    return PriceRequest(
      id: id,
      productName: productName,
      storeName: storeName,
      requestRewardTokens: requestRewardTokens,
      requesterName: requesterName,
      status: status ?? this.status,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      distance: distance,
    );
  }
}
