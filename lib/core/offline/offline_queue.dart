import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single action the user took while offline, waiting to be replayed once
/// connectivity returns. Kept deliberately small and JSON-serialisable.
class PendingOp {
  PendingOp({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  /// Local unique id (timestamp-based) so we can de-dupe and remove precisely.
  final String id;

  /// 'submission' | 'request'
  final String type;

  /// The exact body the corresponding service needs to replay the call.
  final Map<String, dynamic> payload;

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingOp.fromJson(Map<String, dynamic> json) => PendingOp(
    id: json['id'] as String,
    type: json['type'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Durable outbox for actions made offline (NFR-22). Backed by
/// shared_preferences so it survives app restarts. Submissions and price
/// requests are queued here when there's no connection and drained by
/// [SyncService] on reconnect.
class OfflineQueue {
  static const _key = 'offline_outbox_v1';

  Future<List<PendingOp>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PendingOp.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<PendingOp> ops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(ops.map((o) => o.toJson()).toList()),
    );
  }

  Future<void> enqueue(PendingOp op) async {
    final ops = await all();
    ops.add(op);
    await _persist(ops);
  }

  Future<void> remove(String id) async {
    final ops = await all();
    ops.removeWhere((o) => o.id == id);
    await _persist(ops);
  }

  Future<int> count() async => (await all()).length;

  /// Drops every queued op. Called on sign-out so one account's pending writes
  /// never leak into the next session on the same device.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final offlineQueue = OfflineQueue();
