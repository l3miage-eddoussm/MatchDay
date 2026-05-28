import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/user_movie_action.dart';

class MovieRow extends StatelessWidget {
  final UserMovieAction action;
  final bool showRating;

  const MovieRow({super.key, required this.action, required this.showRating});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF0F0F0F))),
      ),
      child: Row(
        children: [
          _MoviePoster(posterPath: action.posterPath),
          const SizedBox(width: 14),
          Expanded(child: _MovieInfo(action: action)),
          const SizedBox(width: 12),
          if (showRating)
            _RatingBadge(rating: action.rating ?? 0, trophy: action.trophy)
          else
            const Icon(Icons.bookmark_rounded, color: Color(0xFFE53935), size: 18),
        ],
      ),
    );
  }
}

class _MoviePoster extends StatelessWidget {
  final String posterPath;
  const _MoviePoster({required this.posterPath});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: posterPath.isNotEmpty
        ? Image.network(
      '${AppConstants.tmdbImageBaseUrl}/w200$posterPath',
      width: 38,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _PosterFallback(),
    )
        : const _PosterFallback(),
  );
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(5),
    ),
  );
}

class _MovieInfo extends StatelessWidget {
  final UserMovieAction action;
  const _MovieInfo({required this.action});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        action.movieTitle,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      if (action.directors.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(
          action.directors.join(', '),
          style: const TextStyle(color: Color(0xFF3A3A3A), fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      if (action.genres.isNotEmpty) ...[
        const SizedBox(height: 4),
        Wrap(
          children: action.genres.take(2).map((g) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1A1A1A)),
            ),
            child: Text(
              g,
              style: const TextStyle(
                color: Color(0xFF3A3A3A),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          )).toList(),
        ),
      ],
    ],
  );
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  final TrophyLevel? trophy;
  const _RatingBadge({required this.rating, this.trophy});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1A1A1A)),
        ),
        child: Text(
          '${rating.toStringAsFixed(0)}/10',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: List.generate(5, (s) {
          final filled = (s + 1) * 2 <= rating;
          final half = !filled && s * 2 < rating && (s + 1) * 2 > rating;
          return Icon(
            filled ? Icons.star_rounded : half ? Icons.star_half_rounded : Icons.star_outline_rounded,
            color: const Color(0xFFE53935),
            size: 12,
          );
        }),
      ),
      if (trophy != null) ...[
        const SizedBox(height: 4),
        Text(trophy!.emoji, style: const TextStyle(fontSize: 12)),
      ],
    ],
  );
}