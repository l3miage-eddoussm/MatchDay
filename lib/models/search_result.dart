import 'movie.dart';

class SearchPerson {
  final int          id;
  final String       name;
  final String       profilePath;
  final String       knownForDepartment;
  final List<String> knownForTitles;

  const SearchPerson({
    required this.id,
    required this.name,
    required this.profilePath,
    required this.knownForDepartment,
    required this.knownForTitles,
  });

  factory SearchPerson.fromJson(Map<String, dynamic> json) {
    final knownFor = (json['known_for'] as List? ?? [])
        .map((e) => (e['title'] ?? e['name'] ?? '') as String)
        .where((t) => t.isNotEmpty)
        .take(2)
        .toList();
    return SearchPerson(
      id:                 json['id'] as int,
      name:               json['name'] as String? ?? '',
      profilePath:        json['profile_path'] as String? ?? '',
      knownForDepartment: json['known_for_department'] as String? ?? '',
      knownForTitles:     knownFor,
    );
  }

  String get profileUrl =>
      'https://image.tmdb.org/t/p/w342$profilePath';
}

sealed class SearchResult {
  const SearchResult();
}

class MovieResult extends SearchResult {
  final Movie movie;
  const MovieResult(this.movie);
}

class PersonResult extends SearchResult {
  final SearchPerson person;
  const PersonResult(this.person);
}