import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class DownloadResult {
  final bool success;
  final String? errorMessage;

  DownloadResult.ok() : success = true, errorMessage = null;
  DownloadResult.fail(this.errorMessage) : success = false;
}

class DownloadService {
  static Future<DownloadResult> downloadVideo({
    required String url,
    required String fileName,
    required Map<String, String> headers,
    required void Function(double progress) onProgress,
  }) async {
    try {
      // Check/request permission to write to the device's gallery.
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          return DownloadResult.fail(
            "Storage permission denied. Enable it in phone Settings > Apps > Video Downloader > Permissions.",
          );
        }
      }

      // Step 1: download to a private temp folder first (fast, no permission issues).
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/$fileName";

      final dio = Dio();
      await dio.download(
        url,
        tempPath,
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
            // Reserve the last 5% of the bar for the gallery-save step.
            onProgress((received / total) * 0.95);
          }
        },
      );

      final tempFile = File(tempPath);
      if (!await tempFile.exists() || await tempFile.length() == 0) {
        return DownloadResult.fail("Downloaded file was empty or corrupted.");
      }

      // Step 2: move it into the real public Gallery/Downloads (visible to the user).
      await Gal.putVideo(tempPath, album: "Video Downloader");
      onProgress(1.0);

      // Clean up the temp copy now that it's safely in the gallery.
      try {
        await tempFile.delete();
      } catch (_) {
        // Non-fatal if cleanup fails.
      }

      return DownloadResult.ok();
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
