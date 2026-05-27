import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../utils/app_router.dart';
import '../pages/movie_detail_page.dart';

class SearchMovieCard extends StatelessWidget {
  final Movie movie;

  const SearchMovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(fadeRoute(MovieDetailPage(movie: movie))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              movie.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF1E1E1E),
                child: Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.white12, size: 40),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD000000)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                        const Spacer(),
                        if (movie.releaseDate.length >= 4)
                          Text(
                            movie.releaseDate.substring(0, 4),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}