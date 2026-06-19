import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
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
    // P4: disk-cached so avatars don't refetch on every rebuild (NFR-01).
    return CachedNetworkImageProvider(url);
  }
  if (kIsWeb) return null;
  return FileImage(File(url));
}
