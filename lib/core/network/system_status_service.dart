import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/core/network/api_client.dart';

class SystemStatus {
  final bool maintenance;
  final String message;

  const SystemStatus({required this.maintenance, required this.message});

  factory SystemStatus.fromJson(Map<String, dynamic> json) => SystemStatus(
    maintenance: json['maintenance'] as bool? ?? false,
    message: json['message'] as String? ?? '',
  );
}

class SystemStatusService {
  Future<SystemStatus> getStatus() async {
    final res = await apiClient.get('/system/status');
    return SystemStatus.fromJson(res.data as Map<String, dynamic>);
  }
}

final systemStatusService = SystemStatusService();

final systemStatusProvider = FutureProvider<SystemStatus>((ref) async {
  return systemStatusService.getStatus();
});
