import 'package:flutter/material.dart';
import '../models/video_info.dart';

class PreviewCard extends StatelessWidget {
  final VideoInfo video;
  const PreviewCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF141A29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF232B3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (video.thumbnail.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                video.thumbnail,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFF1C2434),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B7385)),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  color: const Color(0xFF1C2434),
                  child: const Icon(Icons.broken_image, size: 40, color: Color(0xFF6B7385)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF9AA3B2)),
                    const SizedBox(width: 4),
                    Text(
                      video.formattedDuration,
                      style: const TextStyle(color: Color(0xFF9AA3B2), fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
