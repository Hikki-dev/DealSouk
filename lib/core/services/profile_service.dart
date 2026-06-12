import '../models/models.dart';
import 'api_client.dart';

class ProfileData {
  final String id;
  final String displayName;
  final String? homeArea;
  final String preferredLocale;
  final int tokenBalance;
  final double accuracyRating;
  final bool isAdmin;
  final int totalSubmissions;
  final int approvedSubmissions;

  const ProfileData({
    required this.id,
    required this.displayName,
    this.homeArea,
    required this.preferredLocale,
    required this.tokenBalance,
    required this.accuracyRating,
    required this.isAdmin,
    required this.totalSubmissions,
    required this.approvedSubmissions,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        homeArea: json['homeArea'] as String?,
        preferredLocale: json['preferredLocale'] as String? ?? 'en',
        tokenBalance: json['tokenBalance'] as int? ?? 0,
        accuracyRating: (json['accuracyRating'] as num?)?.toDouble() ?? 100.0,
        isAdmin: json['isAdmin'] as bool? ?? false,
        totalSubmissions: json['totalSubmissions'] as int? ?? 0,
        approvedSubmissions: json['approvedSubmissions'] as int? ?? 0,
      );
}

class ProfileService {
  Future<ProfileData> getMyProfile() async {
    final res = await apiClient.get('/profile/me');
    return ProfileData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TokenTransaction>> getTransactions({int page = 0}) async {
    final res = await apiClient.get('/profile/me/transactions', params: {'page': page});
    final list = res.data as List<dynamic>;
    return list
        .map((e) => TokenTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateProfile({
    String? displayName,
    String? homeArea,
    String? preferredLocale,
  }) async {
    await apiClient.patch('/profile/me', data: {
      if (displayName != null) 'displayName': displayName,
      if (homeArea != null) 'homeArea': homeArea,
      if (preferredLocale != null) 'preferredLocale': preferredLocale,
    });
  }
}

final profileService = ProfileService();
