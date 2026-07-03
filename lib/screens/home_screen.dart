import 'dart:async';
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
  bool _downloadSuccess = false;
  double _progress = 0;
  String? _error;
  bool _showSlowServerHint = false;
  Timer? _slowHintTimer;

  Future<void> _fetchPreview() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _video = null;
      _downloadSuccess = false;
      _showSlowServerHint = false;
    });

    _slowHintTimer?.cancel();
    _slowHintTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _loading) {
        setState(() => _showSlowServerHint = true);
      }
    });

    await _logEvent("extract_requested");

    try {
      final result = await ApiService.extract(url);
      setState(() => _video = result);
      await _logEvent("extract_success");
    } catch (e) {
      setState(() => _error = e.toString());
      await _logEvent("extract_failed");
    } finally {
      _slowHintTimer?.cancel();
      setState(() {
        _loading = false;
        _showSlowServerHint = false;
      });
    }
  }

  Future<void> _download() async {
    if (_video == null) return;
    setState(() {
      _downloading = true;
      _downloadSuccess = false;
      _progress = 0;
    });

    await _logEvent("download_started");

    final safeTitle = _video!.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final fileName = "$safeTitle.${_video!.ext}";

    final result = await DownloadService.downloadVideo(
      sourceUrl: _controller.text.trim(),
      fileName: fileName,
      onProgress: (p) => setState(() => _progress = p),
    );

    setState(() => _downloading = false);
    if (!mounted) return;

    if (result.success) {
      setState(() => _downloadSuccess = true);
      await _logEvent("download_success");
    } else {
      await _logEvent("download_failed");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? "Download failed. Try another video."),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _logEvent(String name) async {
    try {
      await _analytics.logEvent(name: name);
    } catch (_) {
      // Firebase not configured yet or unavailable; skip silently.
    }
  }

  @override
  void dispose() {
    _slowHintTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildInputCard(),
              if (_showSlowServerHint) ...[
                const SizedBox(height: 12),
                _buildSlowServerHint(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(_error!),
              ],
              if (_video != null) ...[
                const SizedBox(height: 24),
                PreviewCard(video: _video!),
                const SizedBox(height: 16),
                _buildDownloadArea(),
              ],
              if (_video == null && _error == null) ...[
                const SizedBox(height: 32),
                _buildInstructions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
            ),
          ),
          child: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Video Downloader",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                "No login. No watermark.",
                style: TextStyle(color: Color(0xFF9AA3B2), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141A29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF232B3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Paste a video link",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _fetchPreview(),
            decoration: InputDecoration(
              hintText: "https://...",
              hintStyle: const TextStyle(color: Color(0xFF6B7385)),
              filled: true,
              fillColor: const Color(0xFF0F1522),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A3244)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A3244)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F46E5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _fetchPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Get Video",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlowServerHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF93A3FF)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Server is waking up — this can take up to a minute on first use.",
              style: TextStyle(color: Color(0xFFB7C0D8), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A2626)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadArea() {
    if (_downloading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141A29),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor: const Color(0xFF232B3D),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progress > 0 ? "${(_progress * 100).toStringAsFixed(0)}%" : "Starting download...",
              style: const TextStyle(color: Color(0xFF9AA3B2), fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_downloadSuccess) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13291D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1F5138)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Saved to your Gallery.",
                style: TextStyle(color: Color(0xFFA7F3D0), fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: _download,
              child: const Text("Download again"),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _download,
        icon: const Icon(Icons.download_rounded, color: Colors.white),
        label: const Text(
          "Download",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final steps = [
      ("1", "Copy a video link", "From YouTube, TikTok, Instagram, or most other platforms."),
      ("2", "Paste it above", "Tap the box and paste, then tap Get Video."),
      ("3", "Preview & download", "Check the title and length, then tap Download to save it."),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141A29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF232B3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How it works",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 14),
          for (final step in steps) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2740),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      step.$1,
                      style: const TextStyle(
                        color: Color(0xFF93A3FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.$3,
                          style: const TextStyle(color: Color(0xFF9AA3B2), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
