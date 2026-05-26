import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_action_service.dart';
import '../constants.dart';
import '../pages/movie_detail_page.dart';

class CollectionMovieCard extends StatelessWidget {
  final Movie movie;
  final bool isCurrent;
  final bool isLast;

  const CollectionMovieCard({
    super.key,
    required this.movie,
    required this.isCurrent,
    required this.isLast,
  });

  String get _year => movie.releaseDate.length >= 4
      ? movie.releaseDate.substring(0, 4)
      : '—';

  @override
  Widget build(BuildContext context) {
    final userAction = MovieActionService().getAction(movie.id);
    final hasRating  = userAction?.rating != null;
    final rating     = userAction?.rating?.toInt() ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MovieDetailPage(movie: movie)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFF1E1E1E)
                : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              _PosterThumbnail(posterPath: movie.posterPath),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isCurrent) const _CurrentFilmBadge(),
                      if (isCurrent) const SizedBox(height: 6),
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _year,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (hasRating) ...[
                        const SizedBox(height: 6),
                        _StarRating(rating: rating),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white24,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterThumbnail extends StatelessWidget {
  final String posterPath;

  static const _placeholder = Color(0xFF2A2A2A);

  const _PosterThumbnail({required this.posterPath});

  Widget _fallback() => Container(
    width: 70,
    height: 100,
    color: _placeholder,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(14),
        bottomLeft: Radius.circular(14),
      ),
      child: posterPath.isEmpty
          ? _fallback()
          : Image.network(
        '${AppConstants.tmdbImageBaseUrl}/w200$posterPath',
        width: 70,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }
}

class _CurrentFilmBadge extends StatelessWidget {
  const _CurrentFilmBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'CE FILM',
        style: TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(
          5,
              (i) => Icon(
            i < (rating / 2).round()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: Colors.white54,
            size: 12,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$rating/10',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}