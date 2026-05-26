import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../pages/movie_detail_page.dart';

class CineMatchResultCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onRetry;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  static const _red  = Color(0xFFFF0000);
  static const _card = Color(0xFF1A1A1A);

  const CineMatchResultCard({
    super.key,
    required this.movie,
    required this.onRetry,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieDetailPage(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VOTRE FILM CE SOIR',
                style: TextStyle(
                  color: _red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'On a trouvé !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => _openDetail(context),
                child: _MoviePosterCard(movie: movie),
              ),
              if (movie.overview.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  movie.overview,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              _ActionButton(
                label: 'Voir le film',
                onPressed: () => _openDetail(context),
                filled: true,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Autre suggestion',
                onPressed: onRetry,
                filled: false,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                label: "Retour à l'accueil",
                onPressed: () => Navigator.of(context).pop(),
                filled: false,
                subtle: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoviePosterCard extends StatelessWidget {
  final Movie movie;
  static const _card = Color(0xFF1A1A1A);

  const _MoviePosterCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          _PosterImage(posterPath: movie.posterPath, posterUrl: movie.posterUrl),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _PosterOverlay(movie: movie),
          ),
        ],
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  final String posterPath;
  final String posterUrl;
  static const _card = Color(0xFF1A1A1A);

  const _PosterImage({required this.posterPath, required this.posterUrl});

  Widget _placeholder() => Container(
    height: 420,
    color: _card,
    child: const Center(
      child: Icon(Icons.movie, color: Color(0xFF333333), size: 60),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (posterPath.isEmpty) return _placeholder();
    return Image.network(
      posterUrl,
      width: double.infinity,
      height: 420,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }
}

class _PosterOverlay extends StatelessWidget {
  final Movie movie;
  const _PosterOverlay({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xEE000000)],
          stops: [0.3, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 4),
              Text(
                movie.voteAverage.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                ' / 10',
                style: TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
              if (movie.releaseDate.length >= 4) ...[
                const SizedBox(width: 14),
                Text(
                  movie.releaseDate.substring(0, 4),
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool subtle;

  static const _card = Color(0xFF1A1A1A);

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.filled,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (subtle) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),
        ),
      );
    }
    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: _card,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}