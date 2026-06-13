import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart'
    if (dart.library.io) 'file_download_helper_mobile.dart';

abstract class FileDownloadHelper {
  static Future<void> downloadFile(List<int> bytes, String fileName) async {
    await saveAndOpen(bytes, fileName);
  }
}
