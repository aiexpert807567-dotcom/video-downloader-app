class VideoInfo {
  final String title;
  final String thumbnail;
  final int duration;
  final String directUrl;
  final String ext;
  final Map<String, String> headers;

  VideoInfo({
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.directUrl,
    required this.ext,
    required this.headers,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        headers[key.toString()] = value.toString();
      });
    }

    return VideoInfo(
      title: json['title'] ?? 'Untitled',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? 0,
      directUrl: json['direct_url'] ?? '',
      ext: json['ext'] ?? 'mp4',
      headers: headers,
    );
  }

  String get formattedDuration {
    final mins = duration ~/ 60;
    final secs = duration % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }
}
