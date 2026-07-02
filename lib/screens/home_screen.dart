import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/video_info.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../widgets/preview_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _analytics = FirebaseAnalytics.instance;

  VideoInfo? _video;
  bool _loading = false;
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _fetchPreview() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _video = null;
    });

    await _analytics.logEvent(name: "extract_requested");

    try {
      final result = await ApiService.extract(url);
      setState(() => _video = result);
      await _analytics.logEvent(name: "extract_success");
    } catch (e) {
      setState(() => _error = e.toString());
      await _analytics.logEvent(name: "extract_failed");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    if (_video == null) return;
    setState(() {
      _downloading = true;
      _progress = 0;
    });

    await _analytics.logEvent(name: "download_started");

    final safeTitle = _video!.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final fileName = "$safeTitle.${_video!.ext}";

    final path = await DownloadService.downloadVideo(
      url: _video!.directUrl,
      fileName: fileName,
      onProgress: (p) => setState(() => _progress = p),
    );

    setState(() => _downloading = false);
    if (!mounted) return;

    if (path != null) {
      await _analytics.logEvent(name: "download_success");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Saved to $path")));
    } else {
      await _analytics.logEvent(name: "download_failed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download failed. Try again.")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Downloader")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Paste video link here",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _fetchPreview,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Go"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_video != null) ...[
                PreviewCard(video: _video!),
                const SizedBox(height: 16),
                if (_downloading)
                  Column(
                    children: [
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Text("${(_progress * 100).toStringAsFixed(0)}%"),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _download,
                    icon: const Icon(Icons.download),
                    label: const Text("Download"),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
