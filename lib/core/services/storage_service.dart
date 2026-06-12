import 'dart:io';
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
    return _upload(File(photo.path), folder: 'receipts');
  }

  /// Opens gallery and uploads the image.
  Future<String?> pickAndUploadReceipt() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (photo == null) return null;
    return _upload(File(photo.path), folder: 'receipts');
  }

  Future<String?> _upload(File file, {required String folder}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = file.path.split('.').last;
      final ref = _storage.ref('$folder/$uid/$ts.$ext');

      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}

final storageService = StorageService();
