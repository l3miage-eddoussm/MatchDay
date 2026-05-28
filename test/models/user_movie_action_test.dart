import 'package:cineart/models/user_movie_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrophyLevel extensions', () {
    test('labels corrects', () {
      expect(TrophyLevel.bronze.label, 'Bronze');
      expect(TrophyLevel.silver.label, 'Argent');
      expect(TrophyLevel.gold.label, 'Or');
      expect(TrophyLevel.platinum.label, 'Platine');
    });

    test('emojis corrects', () {
      expect(TrophyLevel.bronze.emoji, '🥉');
      expect(TrophyLevel.silver.emoji, '🥈');
      expect(TrophyLevel.gold.emoji, '🥇');
      expect(TrophyLevel.platinum.emoji, '💎');
    });

    test('colors corrects', () {
      expect(TrophyLevel.bronze.color, 0xFFCD7F32);
      expect(TrophyLevel.platinum.color, 0xFF00E5FF);
    });
  });

  group('trophyFromScore', () {
    test('retourne null en dessous de 3', () {
      expect(trophyFromScore(0), isNull);
      expect(trophyFromScore(2), isNull);
    });

    test('retourne bronze entre 3 et 4', () {
      expect(trophyFromScore(3), TrophyLevel.bronze);
      expect(trophyFromScore(4), TrophyLevel.bronze);
    });

    test('retourne silver entre 5 et 6', () {
      expect(trophyFromScore(5), TrophyLevel.silver);
      expect(trophyFromScore(6), TrophyLevel.silver);
    });

    test('retourne gold entre 7 et 9', () {
      expect(trophyFromScore(7), TrophyLevel.gold);
      expect(trophyFromScore(9), TrophyLevel.gold);
    });

    test('retourne platinum à 10', () {
      expect(trophyFromScore(10), TrophyLevel.platinum);
    });
  });

  group('UserMovieAction', () {
    final baseAction = UserMovieAction(
      movieId: 42,
      movieTitle: 'The Dark Knight',
      posterPath: '/dk.jpg',
      rating: 9.0,
      watchLater: false,
      review: 'Chef-d\'œuvre',
      quizCompleted: true,
      trophy: TrophyLevel.gold,
      ratedAt: DateTime(2024, 6, 15),
      releaseYear: 2008,
      genres: ['Action', 'Drame'],
      directors: ['Christopher Nolan'],
      topActors: ['Christian Bale'],
    );

    test('toJson sérialise correctement', () {
      final json = baseAction.toJson();
      expect(json['movieId'], 42);
      expect(json['movieTitle'], 'The Dark Knight');
      expect(json['rating'], 9.0);
      expect(json['trophy'], 'gold');
      expect(json['genres'], ['Action', 'Drame']);
    });

    test('fromJson désérialise correctement', () {
      final json = baseAction.toJson();
      final result = UserMovieAction.fromJson(json);
      expect(result.movieId, 42);
      expect(result.rating, 9.0);
      expect(result.trophy, TrophyLevel.gold);
      expect(result.genres, ['Action', 'Drame']);
    });

    test('fromJson → toJson est idempotent', () {
      final json = baseAction.toJson();
      expect(UserMovieAction.fromJson(json).toJson(), json);
    });

    test('fromJson sans trophy retourne null', () {
      final json = baseAction.toJson()..['trophy'] = null;
      expect(UserMovieAction.fromJson(json).trophy, isNull);
    });

    test('fromJson trophy inconnu retourne bronze (orElse)', () {
      final json = baseAction.toJson()..['trophy'] = 'diamond';
      expect(UserMovieAction.fromJson(json).trophy, TrophyLevel.bronze);
    });

    test('hasReview retourne true si review non vide', () {
      expect(baseAction.hasReview, isTrue);
    });

    test('hasReview retourne false si review null', () {
      final noReview = baseAction.copyWith(review: null);
      expect(noReview.hasReview, isFalse);
    });

    test('hasReview retourne false si review vide', () {
      final emptyReview = baseAction.copyWith(review: '   ');
      expect(emptyReview.hasReview, isFalse);
    });

    test('ratedYear retourne l\'année de ratedAt', () {
      expect(baseAction.ratedYear, 2024);
    });

    test('posterUrl construit la bonne URL', () {
      expect(baseAction.posterUrl, contains('/w300/dk.jpg'));
    });

    test('copyWith modifie uniquement le champ ciblé', () {
      final updated = baseAction.copyWith(rating: 5.0);
      expect(updated.rating, 5.0);
      expect(updated.movieTitle, 'The Dark Knight');
      expect(updated.trophy, TrophyLevel.gold);
    });

    test('copyWith avec rating null', () {
      final updated = baseAction.copyWith(rating: null);
      expect(updated.rating, isNull);
    });

    test('toMovie retourne un Movie avec les bons champs', () {
      final movie = baseAction.toMovie();
      expect(movie.id, 42);
      expect(movie.title, 'The Dark Knight');
      expect(movie.posterPath, '/dk.jpg');
    });
  });
}