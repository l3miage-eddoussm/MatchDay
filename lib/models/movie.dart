class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final String releaseDate;
  final List<String> genres;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genres,
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
        ? List<String>.from(
        (json['genres'] as List).map((g) => g['name']))
        : [],
  );

  String get posterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';
  String get backdropUrl => 'https://image.tmdb.org/t/p/w1280$backdropPath';
}