import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../pages/movie_detail_page.dart';

class SimilarMoviesSection extends StatelessWidget {
  final List<Movie> movies;

  const SimilarMoviesSection({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MovieDetailPage(movie: movie),
              ),
            ),
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: movie.posterPath.isNotEmpty
                        ? Image.network(
                      movie.posterUrl,
                      width: 120,
                      height: 170,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 170,
                        color: const Color(0xFF1A1A1A),
                      ),
                    )
                        : Container(
                      width: 120,
                      height: 170,
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.movie,
                          color: Color(0xFF333333)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}