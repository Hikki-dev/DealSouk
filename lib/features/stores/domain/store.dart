class Store {
  final String id;
  final String name;
  final String branch;
  final double distance;
  final int pricesCount;
  final String freshness;
  final double xOffset;
  final double yOffset;
  final int lastUpdatedHoursAgo;
  final double lat;
  final double lng;

  Store({
    required this.id,
    required this.name,
    required this.branch,
    required this.distance,
    required this.pricesCount,
    required this.freshness,
    required this.xOffset,
    required this.yOffset,
    this.lastUpdatedHoursAgo = 2,
    this.lat = 25.0771,
    this.lng = 55.1328,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    final hoursAgo =
        json['lastUpdatedHoursAgo'] as int? ??
        (json['lastUpdatedAt'] != null
            ? DateTime.now()
                  .difference(DateTime.parse(json['lastUpdatedAt'] as String))
                  .inHours
            : 48);
    String freshness;
    if (json['isStale'] == true) {
      freshness = 'Updated ${hoursAgo}h ago';
    } else if (hoursAgo < 1) {
      freshness = 'Fresh';
    } else if (hoursAgo < 6) {
      freshness = 'Fresh';
    } else {
      freshness = 'Updated ${hoursAgo}h ago';
    }
    return Store(
      id: json['id'] as String,
      name: json['chain'] as String,
      branch: json['branchName'] as String,
      distance: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      pricesCount: (json['activeSubmissionCount'] as int?) ?? 0,
      freshness: freshness,
      xOffset: 0.5,
      yOffset: 0.5,
      lastUpdatedHoursAgo: hoursAgo,
      lat: (json['lat'] as num?)?.toDouble() ?? 25.0771,
      lng: (json['lng'] as num?)?.toDouble() ?? 55.1328,
    );
  }
}
