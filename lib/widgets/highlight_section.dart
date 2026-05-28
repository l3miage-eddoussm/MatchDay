import 'package:flutter/material.dart';

class HighlightSection extends StatelessWidget {
  final int year;
  final String? actor;
  final String? director;
  final String? genre;
  final String? actorImageUrl;
  final String? directorImageUrl;

  const HighlightSection({
    super.key,
    required this.year,
    this.actor,
    this.director,
    this.genre,
    this.actorImageUrl,
    this.directorImageUrl,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOP $year',
          style: const TextStyle(
            color: Color(0xFF2E2E2E),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        if (actor != null || director != null)
          Row(
            children: [
              if (actor != null)
                Expanded(
                  child: HighlightTile(
                    icon: Icons.person_rounded,
                    label: 'ACTEUR',
                    value: actor!,
                    imageUrl: actorImageUrl,
                  ),
                ),
              if (actor != null && director != null) const SizedBox(width: 10),
              if (director != null)
                Expanded(
                  child: HighlightTile(
                    icon: Icons.videocam_rounded,
                    label: 'RÉALISATEUR',
                    value: director!,
                    imageUrl: directorImageUrl,
                  ),
                ),
            ],
          ),
        if (genre != null) ...[
          if (actor != null || director != null) const SizedBox(height: 10),
          GenreHighlightTile(genre: genre!),
        ],
        const SizedBox(height: 22),
        const ColoredBox(color: Color(0xFF111111), child: SizedBox(height: 1, width: double.infinity)),
      ],
    ),
  );
}

class HighlightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? imageUrl;

  const HighlightTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF141414)),
    ),
    child: Row(
      children: [
        ClipOval(
          child: imageUrl != null
              ? Image.network(
            imageUrl!,
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _IconFallback(icon: icon),
          )
              : _IconFallback(icon: icon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2E2E2E),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class GenreHighlightTile extends StatelessWidget {
  final String genre;
  const GenreHighlightTile({super.key, required this.genre});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF141414)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A1A1A)),
          ),
          child: const Icon(Icons.local_movies_rounded, color: Color(0xFF333333), size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GENRE FAVORI',
              style: TextStyle(
                color: Color(0xFF2E2E2E),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              genre,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1E1E1E), size: 12),
      ],
    ),
  );
}

class _IconFallback extends StatelessWidget {
  final IconData icon;
  const _IconFallback({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: const BoxDecoration(color: Color(0xFF111111), shape: BoxShape.circle),
    child: Icon(icon, color: const Color(0xFF333333), size: 18),
  );
}