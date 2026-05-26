import 'movie.dart';

class CollectionDetail {
  final String name;
  final String overview;
  final String backdropPath;
  final List<Movie> parts;

  const CollectionDetail({
    required this.name,
    required this.overview,
    required this.backdropPath,
    required this.parts,
  });

  String get backdropUrl =>
      'https://image.tmdb.org/t/p/w1280$backdropPath';
}