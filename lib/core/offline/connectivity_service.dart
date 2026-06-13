import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isOnline(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);

/// Streams the device's online/offline state (NFR-22). Emits the current state
/// immediately, then every change. Used to gate writes and to trigger sync when
/// connectivity returns.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _isOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_isOnline);
});

/// Convenience boolean. Defaults to `true` until the first reading resolves, so
/// the very first action isn't wrongly treated as offline.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});

/// A one-shot connectivity check for code paths that aren't widgets (e.g. just
/// before firing a network write).
Future<bool> isCurrentlyOnline() async {
  return _isOnline(await Connectivity().checkConnectivity());
}
