import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:dealsouk/core/network/api_client.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  /// Opens the camera and returns the captured file WITHOUT uploading.
  /// Returns null if the user cancelled.
  Future<XFile?> capturePhotoFile() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 55,
      maxWidth: 800,
    );
  }

  /// Opens the gallery and returns the selected file WITHOUT uploading.
  /// Returns null if the user cancelled.
  Future<XFile?> pickPhotoFile() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 800,
    );
  }

  /// Uploads a previously-captured [file] for price-submission proof.
  /// Returns the download URL, or null on failure.
  Future<String?> uploadProofFile(XFile file, {required bool isReceipt}) {
    return _upload(
      file,
      directFolder: isReceipt ? 'receipts' : 'price-labels',
      signedKind: isReceipt ? 'receipt' : 'price_label',
    );
  }

  /// Opens camera and uploads the image to Firebase Storage.
  /// Returns the download URL, or null if the user cancelled.
  Future<String?> captureAndUploadReceipt() async {
    final photo = await capturePhotoFile();
    if (photo == null) return null;
    return _upload(photo, directFolder: 'receipts', signedKind: 'receipt');
  }

  /// Opens the camera and uploads a price-label photo to Firebase Storage.
  /// Returns the download URL, or null if the user cancelled / the upload failed.
  Future<String?> captureAndUploadPriceLabel() async {
    final photo = await capturePhotoFile();
    if (photo == null) return null;
    return _upload(
      photo,
      directFolder: 'price-labels',
      signedKind: 'price_label',
    );
  }

  /// Opens gallery and uploads the image.
  Future<String?> pickAndUploadReceipt() async {
    final photo = await pickPhotoFile();
    if (photo == null) return null;
    return _upload(photo, directFolder: 'receipts', signedKind: 'receipt');
  }

  /// Opens the gallery to pick an avatar and uploads it.
  Future<String?> pickAndUploadAvatar() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 700,
    );
    if (photo == null) return null;

    return _upload(photo, directFolder: 'avatars', signedKind: 'avatar');
  }

  /// Opens the camera to take a new avatar photo and uploads it.
  Future<String?> captureAndUploadAvatar() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 65,
      maxWidth: 700,
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
      imageQuality: 65,
      maxWidth: 700,
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _logUploadFailure('upload', 'No authenticated Firebase user.');
      return null;
    }

    final ext = _normalizedExtension(file.name);
    final contentType = _contentTypeForExtension(ext);
    final bytes = await file.readAsBytes();

    for (var attempt = 1; attempt <= 3; attempt++) {
      final url = await _uploadOnce(
        bytes,
        uid: uid,
        directFolder: directFolder,
        ext: ext,
        signedKind: signedKind,
        contentType: contentType,
        attempt: attempt,
      );
      if (url != null) return url;
      if (attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 450 * attempt));
      }
    }

    _logUploadFailure(
      'upload',
      'All upload attempts failed.',
      details: {'kind': signedKind, 'bytes': bytes.length},
    );
    return null;
  }

  Future<String?> _uploadOnce(
    Uint8List bytes, {
    required String uid,
    required String directFolder,
    required String ext,
    required String signedKind,
    required String contentType,
    required int attempt,
  }) async {
    try {
      final signedUrl = await _signedUpload(
        bytes,
        kind: signedKind,
        contentType: contentType,
        attempt: attempt,
      );
      if (signedUrl != null) return signedUrl;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref('$directFolder/$uid/$ts.$ext');
      final downloadToken = _generateDownloadToken();
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {'firebaseStorageDownloadTokens': downloadToken},
        ),
      );
      return _downloadUrlFor(
        bucket: ref.bucket,
        objectPath: ref.fullPath,
        token: downloadToken,
      );
    } on FirebaseException catch (e, st) {
      _logUploadFailure(
        'firebase-sdk',
        e,
        stackTrace: st,
        details: {'attempt': attempt, 'code': e.code},
      );
      return null;
    } catch (e, st) {
      _logUploadFailure(
        'firebase-sdk',
        e,
        stackTrace: st,
        details: {'attempt': attempt},
      );
      return null;
    }
  }

  Future<String?> _signedUpload(
    Uint8List bytes, {
    required String kind,
    required String contentType,
    required int attempt,
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

      final uploadHeaders = <String, dynamic>{
        ...headers,
        Headers.contentLengthHeader: bytes.length,
      };

      await Dio().put<Object>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: uploadHeaders,
          responseType: ResponseType.plain,
        ),
      );
      return downloadUrl;
    } on DioException catch (e, st) {
      _logUploadFailure(
        e.requestOptions.path.contains('/uploads/signed-url')
            ? 'signed-url'
            : 'gcs-put',
        e,
        stackTrace: st,
        details: {
          'attempt': attempt,
          'kind': kind,
          'contentType': contentType,
          'status': e.response?.statusCode,
          'body': _shortResponseBody(e.response?.data),
        },
      );
      return null;
    } catch (e, st) {
      _logUploadFailure(
        'signed-url',
        e,
        stackTrace: st,
        details: {'attempt': attempt, 'kind': kind, 'contentType': contentType},
      );
      return null;
    }
  }

  String? _shortResponseBody(Object? data) {
    if (data == null) return null;
    final text = data.toString();
    return text.length <= 400 ? text : '${text.substring(0, 400)}...';
  }

  String _downloadUrlFor({
    required String bucket,
    required String objectPath,
    required String token,
  }) {
    final encodedPath = Uri.encodeComponent(objectPath);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
        '$encodedPath?alt=media&token=$token';
  }

  String _generateDownloadToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  void _logUploadFailure(
    String stage,
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> details = const {},
  }) {
    if (kReleaseMode) return;
    debugPrint('[StorageService] $stage upload failed: $error; $details');
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
