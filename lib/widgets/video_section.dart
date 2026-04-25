import 'package:flutter/material.dart';
import '../models/movie_detail.dart';

class VideoSection extends StatelessWidget {
  final List<MovieVideo> videos;
  final void Function(String url) onTap;

  const VideoSection({
    super.key,
    required this.videos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final video = videos[index];
          return GestureDetector(
            onTap: () => onTap(video.youtubeUrl),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    video.thumbnailUrl,
                    width: 200,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200,
                      height: 120,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const Icon(Icons.play_circle_filled,
                    color: Colors.white, size: 44),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    video.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}