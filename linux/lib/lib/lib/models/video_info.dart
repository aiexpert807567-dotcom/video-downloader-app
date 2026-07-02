class VideoInfo {
  final String title;
  final String thumbnail;
  final int duration;
  final String directUrl;
  final String ext;

  VideoInfo({
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.directUrl,
    required this.ext,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      title: json['title'] ?? 'Untitled',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? 0,
      directUrl: json['direct_url'] ?? '',
      ext: json['ext'] ?? 'mp4',
    );
  }

  String get formattedDuration {
    final mins = duration ~/ 60;
    final secs = duration % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }
}
