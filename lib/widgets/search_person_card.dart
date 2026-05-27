import 'package:flutter/material.dart';
import '../models/search_result.dart';
import '../pages/person_page.dart';

class SearchPersonCard extends StatelessWidget {
  final SearchPerson person;

  const SearchPersonCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final dept  = person.knownForDepartment;
    final label = dept == 'Directing'
        ? 'Réalisateur'
        : dept == 'Acting'
        ? 'Acteur'
        : dept;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PersonPage(personId: person.id, personName: person.name),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 65,
              child: person.profilePath.isNotEmpty
                  ? Image.network(
                person.profileUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PersonPlaceholder(),
              )
                  : const _PersonPlaceholder(),
            ),
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (label.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (person.knownForTitles.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        person.knownForTitles.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ],
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

class _PersonPlaceholder extends StatelessWidget {
  const _PersonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF2A2A2A),
      child: Center(
        child: Icon(Icons.person_rounded, color: Colors.white12, size: 48),
      ),
    );
  }
}