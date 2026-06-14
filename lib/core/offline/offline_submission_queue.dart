import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dealsouk/features/submissions/data/submissions_service.dart';

class PendingSubmission {
  final String productId;
  final String storeId;
  final double priceAed;
  final bool hasReceipt;
  final String? receiptUrl;
  final int queuedAtMs;

  const PendingSubmission({
    required this.productId,
    required this.storeId,
    required this.priceAed,
    required this.hasReceipt,
    this.receiptUrl,
    required this.queuedAtMs,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'storeId': storeId,
    'priceAed': priceAed,
    'hasReceipt': hasReceipt,
    if (receiptUrl != null) 'receiptUrl': receiptUrl,
    'queuedAtMs': queuedAtMs,
  };

  factory PendingSubmission.fromJson(Map<String, dynamic> json) =>
      PendingSubmission(
        productId: json['productId'] as String,
        storeId: json['storeId'] as String,
        priceAed: (json['priceAed'] as num).toDouble(),
        hasReceipt: json['hasReceipt'] as bool,
        receiptUrl: json['receiptUrl'] as String?,
        queuedAtMs: json['queuedAtMs'] as int,
      );
}

/// Offline-first queue for price submissions.
///
/// When the device has no connectivity, submissions are persisted to
/// SharedPreferences and automatically flushed once the network returns.
/// The queue survives app restarts — any pending entries are flushed on the
/// next successful connection after a cold launch.
class OfflineSubmissionQueue {
  static const _prefsKey = 'offline_submission_queue_v1';

  bool _flushing = false;

  /// Call once at app start. Subscribes to connectivity changes and flushes
  /// any entries that survived from a previous session.
  void init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) flush();
    });
    // Also attempt an immediate flush in case we're already online.
    flush();
  }

  /// Adds [submission] to the persistent queue.
  Future<void> enqueue(PendingSubmission submission) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _decode(prefs.getString(_prefsKey));
    existing.add(submission.toJson());
    await prefs.setString(_prefsKey, jsonEncode(existing));
  }

  /// Number of submissions waiting to be sent.
  Future<int> get pendingCount async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_prefsKey)).length;
  }

  /// Drains the queue. Each item is submitted; failed items are kept for the
  /// next flush attempt. Safe to call concurrently — re-entrant calls are
  /// ignored while a flush is already running.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = _decode(prefs.getString(_prefsKey))
          .map(
            (e) =>
                PendingSubmission.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (pending.isEmpty) return;

      final remaining = <PendingSubmission>[];
      for (final sub in pending) {
        try {
          await submissionsService.create(
            productId: sub.productId,
            storeId: sub.storeId,
            priceAed: sub.priceAed,
            hasReceipt: sub.hasReceipt,
            receiptUrl: sub.receiptUrl,
          );
        } catch (_) {
          remaining.add(sub);
        }
      }

      if (remaining.isEmpty) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(
          _prefsKey,
          jsonEncode(remaining.map((s) => s.toJson()).toList()),
        );
      }
    } finally {
      _flushing = false;
    }
  }

  List<dynamic> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }
}

final offlineSubmissionQueue = OfflineSubmissionQueue();
