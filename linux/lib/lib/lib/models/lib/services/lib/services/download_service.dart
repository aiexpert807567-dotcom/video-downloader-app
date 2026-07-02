import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  static Future<String?> downloadVideo({
    required String url,
    required String fileName,
    required void Function(double progress) onProgress,
  }) async {
    if (Platform.isAndroid) {
      // On Android 13+ this permission is largely a no-op for app-scoped
      // storage, but requesting it keeps older Android versions working.
      await Permission.storage.request();
    }

    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final savePath = "${dir.path}/$fileName";

    final dio = Dio();
    try {
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );
      return savePath;
    } catch (_) {
      return null;
    }
  }
}
