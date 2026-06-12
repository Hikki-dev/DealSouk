import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';

class FcmService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize({
    required void Function(RemoteMessage) onForegroundMessage,
  }) async {
    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Register FCM token with backend
    await _registerToken();

    // Refresh token when it rotates
    _messaging.onTokenRefresh.listen((_) => _registerToken());

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(onForegroundMessage);
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await apiClient.post(
          '/profile/me/fcm-token',
          data: {'fcmToken': token},
        );
      }
    } catch (_) {
      // Not critical — silently skip if backend unreachable
    }
  }

  /// Returns the notification that launched the app from a terminated state
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();
}

final fcmService = FcmService();

/// Shows an in-app banner for foreground notifications
void showFcmBanner(BuildContext context, RemoteMessage message) {
  final title = message.notification?.title ?? 'DealSouk';
  final body = message.notification?.body ?? '';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (body.isNotEmpty) Text(body),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );
}
