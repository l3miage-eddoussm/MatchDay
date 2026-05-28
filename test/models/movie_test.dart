import 'package:cineart/models/movie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Movie', () {
    final json = {
      'id': 1,
      'title': 'Inception',
      'overview': 'A dream within a dream',
      'poster_path': '/inception.jpg',
      'backdrop_path': '/backdrop.jpg',
      'vote_average': 8.8,
      'release_date': '2010-07-16',
      'genres': [
        {'name': 'Science-Fiction'},
        {'name': 'Action'},
      ],
      'belongs_to_collection': null,
    };

    test('fromJson parse correctement', () {
      final movie = Movie.fromJson(json);
      expect(movie.id, 1);
      expect(movie.title, 'Inception');
      expect(movie.voteAverage, 8.8);
      expect(movie.genres, ['Science-Fiction', 'Action']);
      expect(movie.belongsToCollection, isNull);
    });

    test('posterUrl construit la bonne URL', () {
      final movie = Movie.fromJson(json);
      expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w500/inception.jpg');
    });

    test('backdropUrl construit la bonne URL', () {
      final movie = Movie.fromJson(json);
      expect(movie.backdropUrl, 'https://image.tmdb.org/t/p/w1280/backdrop.jpg');
    });

    test('genres vide si absent du json', () {
      final noGenre = Map<String, dynamic>.from(json)..remove('genres');
      expect(Movie.fromJson(noGenre).genres, isEmpty);
    });

    test('fromJson avec collection', () {
      final withCollection = Map<String, dynamic>.from(json)
        ..['belongs_to_collection'] = {
          'id': 10,
          'name': 'Dark Knight Collection',
          'poster_path': '/dk.jpg',
          'backdrop_path': '/dkb.jpg',
        };
      final movie = Movie.fromJson(withCollection);
      expect(movie.belongsToCollection, isNotNull);
      expect(movie.belongsToCollection!.name, 'Dark Knight Collection');
    });
  });

  group('MovieCollection', () {
    test('backdropUrl construit la bonne URL', () {
      final collection = MovieCollection(
        id: 1,
        name: 'Collection',
        posterPath: '/p.jpg',
        backdropPath: '/b.jpg',
      );
      expect(collection.backdropUrl, 'https://image.tmdb.org/t/p/w1280/b.jpg');
    });
  });
}