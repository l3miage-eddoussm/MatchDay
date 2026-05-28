import 'package:flutter/material.dart';
import '../models/user_movie_action.dart';

class TrophyRow extends StatelessWidget {
  final UserMovieAction action;
  const TrophyRow({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final t = action.trophy!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF141414)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E1E1E)),
            ),
            alignment: Alignment.center,
            child: Text(t.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.movieTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  t.label,
                  style: const TextStyle(color: Color(0xFF444444), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (action.posterPath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                'https://image.tmdb.org/t/p/w200${action.posterPath}',
                width: 32,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
        ],
      ),
    );
  }
}