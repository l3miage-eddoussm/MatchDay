import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../pages/person_page.dart';

class MovieInfoHeader extends StatelessWidget {
  final Movie movie;
  final List<CrewMember> directors;

  const MovieInfoHeader({
    super.key,
    required this.movie,
    required this.directors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.white, size: 15),
            const SizedBox(width: 5),
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
              style: TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
            if (movie.releaseDate.isNotEmpty) ...[
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today,
                  color: Color(0xFF666666), size: 13),
              const SizedBox(width: 5),
              Text(
                movie.releaseDate.length >= 4
                    ? movie.releaseDate.substring(0, 4)
                    : movie.releaseDate,
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 13),
              ),
            ],
          ],
        ),
        if (movie.genres.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: movie.genres
                .map(
                  (g) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF444444)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  g,
                  style: const TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 12),
                ),
              ),
            )
                .toList(),
          ),
        ],
        if (directors.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Réalisateur : ',
                style: TextStyle(color: Color(0xFF888888), fontSize: 14),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: directors
                      .where((d) => d.name.isNotEmpty)
                      .map(
                        (d) => GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PersonPage(
                            personId: d.id,
                            personName: d.name,
                          ),
                        ),
                      ),
                      child: Text(
                        d.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Synopsis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          movie.overview.isNotEmpty
              ? movie.overview
              : 'Aucun synopsis disponible.',
          style: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}