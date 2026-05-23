class MovieCollection {
  final int id;
  final String name;
  final String posterPath;
  final String backdropPath;

  MovieCollection({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.backdropPath,
  });

  factory MovieCollection.fromJson(Map<String, dynamic> json) => MovieCollection(
    id: json['id'],
    name: json['name'] ?? '',
    posterPath: json['poster_path'] ?? '',
    backdropPath: json['backdrop_path'] ?? '',
  );

  String get backdropUrl => 'https://image.tmdb.org/t/p/w1280$backdropPath';
}

class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final String releaseDate;
  final List<String> genres;
  final MovieCollection? belongsToCollection;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genres,
    this.belongsToCollection,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
    id: json['id'],
    title: json['title'] ?? '',
    overview: json['overview'] ?? '',
    posterPath: json['poster_path'] ?? '',
    backdropPath: json['backdrop_path'] ?? '',
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    releaseDate: json['release_date'] ?? '',
    genres: json['genres'] != null
        ? List<String>.from((json['genres'] as List).map((g) => g['name']))
        : [],
    belongsToCollection: json['belongs_to_collection'] != null
        ? MovieCollection.fromJson(json['belongs_to_collection'])
        : null,
  );

  String get posterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';
  String get backdropUrl => 'https://image.tmdb.org/t/p/w1280$backdropPath';
}