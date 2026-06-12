class AdminAnalytics {
  final int submissionsToday;
  final int submissionsThisMonth;
  final int activeUsers;
  final int tokensNet;
  final int pendingVouchers;
  final int issuedVouchers;
  final List<TrendingProduct> trendingProducts;
  final List<CoverageArea> coverageAreas;

  const AdminAnalytics({
    required this.submissionsToday,
    required this.submissionsThisMonth,
    required this.activeUsers,
    required this.tokensNet,
    required this.pendingVouchers,
    required this.issuedVouchers,
    required this.trendingProducts,
    required this.coverageAreas,
  });

  factory AdminAnalytics.empty() => const AdminAnalytics(
    submissionsToday: 0,
    submissionsThisMonth: 0,
    activeUsers: 0,
    tokensNet: 0,
    pendingVouchers: 0,
    issuedVouchers: 0,
    trendingProducts: [],
    coverageAreas: [],
  );

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) => AdminAnalytics(
    submissionsToday: json['submissionsToday'] as int? ?? 0,
    submissionsThisMonth: json['submissionsThisMonth'] as int? ?? 0,
    activeUsers: json['activeUsers'] as int? ?? 0,
    tokensNet: json['tokensNet'] as int? ?? 0,
    pendingVouchers: json['pendingVouchers'] as int? ?? 0,
    issuedVouchers: json['issuedVouchers'] as int? ?? 0,
    trendingProducts: (json['trendingProducts'] as List<dynamic>? ?? [])
        .map((e) => TrendingProduct.fromJson(e as Map<String, dynamic>))
        .toList(),
    coverageAreas: (json['coverageAreas'] as List<dynamic>? ?? [])
        .map((e) => CoverageArea.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class TrendingProduct {
  final String name;
  final String category;
  final int submissions;

  const TrendingProduct({
    required this.name,
    required this.category,
    required this.submissions,
  });

  factory TrendingProduct.fromJson(Map<String, dynamic> json) =>
      TrendingProduct(
        name: json['name'] as String? ?? 'Unknown product',
        category: json['category'] as String? ?? 'Unknown',
        submissions: json['submissions'] as int? ?? 0,
      );
}

class CoverageArea {
  final String chain;
  final String branchName;
  final String area;
  final int recentSubmissions;

  const CoverageArea({
    required this.chain,
    required this.branchName,
    required this.area,
    required this.recentSubmissions,
  });

  factory CoverageArea.fromJson(Map<String, dynamic> json) => CoverageArea(
    chain: json['chain'] as String? ?? 'Unknown',
    branchName: json['branchName'] as String? ?? '',
    area: json['area'] as String? ?? 'Unknown',
    recentSubmissions: json['recentSubmissions'] as int? ?? 0,
  );
}
