import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/video_info.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static Future<VideoInfo> extract(String url) async {
    final uri = Uri.parse("${AppConfig.backendBaseUrl}/extract");

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"url": url}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApiException("Could not reach the server. Check your connection.");
    }

    if (response.statusCode == 200) {
      return VideoInfo.fromJson(jsonDecode(response.body));
    } else {
      String detail = "This link could not be processed.";
      try {
        final body = jsonDecode(response.body);
        detail = body['detail'] ?? detail;
      } catch (_) {}
      throw ApiException(detail);
    }
  }
}
