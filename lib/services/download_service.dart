import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  static Future<String?> downloadVideo({
    required String url,
    required String fileName,
    required Map<String, String> headers,
    required void Function(double progress) onProgress,
  }) async {
    if (Platform.isAndroid) {
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
        options: Options(
          headers: headers.isNotEmpty
              ? headers
              : {
                  "User-Agent":
                      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
                },
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );
      return savePath;
    } on DioException catch (e) {
      // Surface the real reason in debug logs instead of a silent null.
      // ignore: avoid_print
      print("Download failed: ${e.type} ${e.message} ${e.response?.statusCode}");
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("Download failed: $e");
      return null;
    }
  }
}
