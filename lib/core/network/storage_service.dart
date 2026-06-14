import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:dealsouk/core/network/api_client.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  /// Opens camera and uploads the image to Firebase Storage.
  /// Returns the download URL, or null if the user cancelled.
  Future<String?> captureAndUploadReceipt() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (photo == null) return null;
    return _upload(photo, directFolder: 'receipts', signedKind: 'receipt');
  }

  /// Opens the camera and uploads a price-label photo to Firebase Storage.
  /// Returns the download URL, or null if the user cancelled / the upload failed.
  Future<String?> captureAndUploadPriceLabel() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (photo == null) return null;
    return _upload(
      photo,
      directFolder: 'price-labels',
      signedKind: 'price_label',
    );
  }

  /// Opens gallery and uploads the image.
  Future<String?> pickAndUploadReceipt() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (photo == null) return null;
    return _upload(photo, directFolder: 'receipts', signedKind: 'receipt');
  }

  /// Opens the gallery to pick an avatar and uploads it.
  Future<String?> pickAndUploadAvatar() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 900,
    );
    if (photo == null) return null;

    return _upload(photo, directFolder: 'avatars', signedKind: 'avatar');
  }

  /// Opens the camera to take a new avatar photo and uploads it.
  Future<String?> captureAndUploadAvatar() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 900,
    );
    if (photo == null) return null;

    return _upload(photo, directFolder: 'avatars', signedKind: 'avatar');
  }

  /// Picks an avatar image and returns its **local file path** without
  /// uploading anywhere. Used for the demo/guest session, whose profile photo
  /// is kept on-device only. Returns null if the user cancelled.
  Future<String?> pickLocalAvatarPath({bool fromCamera = false}) async {
    final photo = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 900,
    );
    return photo?.path;
  }

  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }

  Future<String?> _upload(
    XFile file, {
    required String directFolder,
    required String signedKind,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final ext = _normalizedExtension(file.name);
      final contentType = _contentTypeForExtension(ext);
      final bytes = await file.readAsBytes();

      final signedUrl = await _signedUpload(
        bytes,
        kind: signedKind,
        contentType: contentType,
      );
      if (signedUrl != null) return signedUrl;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref('$directFolder/$uid/$ts.$ext');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _signedUpload(
    List<int> bytes, {
    required String kind,
    required String contentType,
  }) async {
    try {
      final res = await apiClient.post(
        '/uploads/signed-url',
        data: {
          'kind': kind,
          'contentType': contentType,
          'sizeBytes': bytes.length,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final uploadUrl = data['uploadUrl'] as String?;
      final downloadUrl = data['downloadUrl'] as String?;
      final headers = Map<String, dynamic>.from(
        data['requiredHeaders'] as Map? ?? const {},
      );
      if (uploadUrl == null || downloadUrl == null) return null;

      await Dio().put<List<int>>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: headers,
          contentType: contentType,
          responseType: ResponseType.plain,
        ),
      );
      return downloadUrl;
    } catch (_) {
      return null;
    }
  }

  String _normalizedExtension(String fileName) {
    final raw = fileName.split('.').last.toLowerCase();
    return switch (raw) {
      'jpeg' || 'jpg' => 'jpg',
      'png' => 'png',
      'webp' => 'webp',
      'heic' || 'heif' => raw,
      _ => 'jpg',
    };
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'jpg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }
}

final storageService = StorageService();
