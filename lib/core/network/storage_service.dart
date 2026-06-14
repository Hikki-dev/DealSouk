import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
    return _upload(photo, folder: 'receipts');
  }

  /// Opens gallery and uploads the image.
  Future<String?> pickAndUploadReceipt() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (photo == null) return null;
    return _upload(photo, folder: 'receipts');
  }

  /// Opens the gallery to pick an avatar and uploads it.
  Future<String?> pickAndUploadAvatar() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 900,
    );
    if (photo == null) return null;

    return _upload(photo, folder: 'avatars');
  }

  /// Opens the camera to take a new avatar photo and uploads it.
  Future<String?> captureAndUploadAvatar() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 900,
    );
    if (photo == null) return null;

    return _upload(photo, folder: 'avatars');
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

  Future<String?> _upload(XFile file, {required String folder}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = _normalizedExtension(file.name);
      final contentType = _contentTypeForExtension(ext);
      final ref = _storage.ref('$folder/$uid/$ts.$ext');

      final bytes = await file.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
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
