import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../config.dart';

class DownloadResult {
  final bool success;
  final String? errorMessage;

  DownloadResult.ok() : success = true, errorMessage = null;
  DownloadResult.fail(this.errorMessage) : success = false;
}

class DownloadService {
  static Future<DownloadResult> downloadVideo({
    required String sourceUrl,
    required String fileName,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          return DownloadResult.fail(
            "Storage permission denied. Enable it in phone Settings > Apps > Video Downloader > Permissions.",
          );
        }
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/$fileName";

      final dio = Dio();
      // Download from OUR backend's /download endpoint, not the raw CDN
      // link. The backend proxies the video through itself, which avoids
      // IP-locked 403 errors from YouTube/TikTok/Instagram CDNs.
      await dio.download(
        "${AppConfig.backendBaseUrl}/download",
        tempPath,
        data: {"url": sourceUrl},
        options: Options(
          method: "POST",
          headers: {"Content-Type": "application/json"},
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 20),
          validateStatus: (status) => status != null && status < 400,
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress((received / total) * 0.95);
          }
        },
      );

      final tempFile = File(tempPath);
      if (!await tempFile.exists() || await tempFile.length() == 0) {
        return DownloadResult.fail("Downloaded file was empty or corrupted.");
      }

      await Gal.putVideo(tempPath, album: "Video Downloader");
      onProgress(1.0);

      try {
        await tempFile.delete();
      } catch (_) {}

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
