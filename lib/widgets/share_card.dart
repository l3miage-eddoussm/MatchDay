import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/movie.dart';

class ShareCard extends StatelessWidget {
  final Movie  movie;
  final String username;
  final int    rating;
  final String review;

  const ShareCard({
    super.key,
    required this.movie,
    required this.username,
    required this.rating,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: 400,
        height: 600,
        child: Stack(
          fit: StackFit.expand,
          children: [
            movie.posterPath.isNotEmpty
                ? Image.network(
              movie.posterUrl,
              fit: BoxFit.cover,
            )
                : const ColoredBox(color: AppColors.surfaceDark),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xBB000000),
                    Color(0xF2000000),
                  ],
                  stops: [0.25, 0.55, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...List.generate(
                        10,
                            (i) => Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            i < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$rating/10',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      '"$review"',
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(
                        'CINEART',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}