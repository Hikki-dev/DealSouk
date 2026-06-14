import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Resolves a profile avatar string to the right [ImageProvider]:
///   - empty            → null (caller shows a placeholder icon)
///   - http(s) URL      → [NetworkImage]  (Google photo or uploaded avatar)
///   - local file path  → [FileImage]     (guest/demo avatar saved on-device)
///
/// Returns null on web for local paths (dart:io File isn't available there).
ImageProvider? avatarImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return NetworkImage(url);
  }
  if (kIsWeb) return null;
  return FileImage(File(url));
}
