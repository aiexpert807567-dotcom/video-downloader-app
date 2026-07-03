import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadResult {
  final bool success;
  final String? path;
  final String? errorMessage;

  DownloadResult.ok(this.path)
      : success = true,
        errorMessage = null;

  DownloadResult.fail(this.errorMessage)
      : success = false,
        path = null;
}

class DownloadService {
  static Future<DownloadResult> downloadVideo({
    required String url,
    required String fileName,
    required Map<String, String> headers,
    required void Function(double progress) onProgress,
  }) async {
    try {
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      Directory dir;
      try {
        dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } catch (e) {
        return DownloadResult.fail("Could not access storage: $e");
      }

      final savePath = "${dir.path}/$fileName";

      final dio = Dio();
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
          receiveTimeout: const Duration(minutes: 20),
          validateStatus: (status) => status != null && status < 400,
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );
      return DownloadResult.ok(savePath);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final reason = switch (e.type) {
        DioExceptionType.connectionTimeout => "Connection timed out.",
        DioExceptionType.receiveTimeout => "Server took too long to respond.",
        DioExceptionType.badResponse => "Server rejected the request (HTTP $status).",
        DioExceptionType.connectionError => "Could not connect: ${e.message}",
        DioExceptionType.cancel => "Download was cancelled.",
        _ => "Network error: ${e.message}",
      };
      return DownloadResult.fail(reason);
    } catch (e) {
      return DownloadResult.fail("Unexpected error: $e");
    }
  }
}
