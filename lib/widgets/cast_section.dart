import 'package:flutter/material.dart';
import '../models/movie_detail.dart';
import '../pages/person_page.dart';

class CastSection extends StatelessWidget {
  final List<CastMember> cast;

  const CastSection({super.key, required this.cast});

  static Widget _avatarFallback() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFF1A1A1A),
      child: const Icon(Icons.person, color: Color(0xFF333333), size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final member = cast[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PersonPage(
                  personId: member.id,
                  personName: member.name,
                ),
              ),
            ),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: member.profilePath.isNotEmpty
                        ? Image.network(
                      member.profileUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                        : _avatarFallback(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    member.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.character,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
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