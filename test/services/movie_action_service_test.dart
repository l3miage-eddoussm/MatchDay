import 'package:cineart/models/movie_detail.dart';
import 'package:cineart/models/user_movie_action.dart';
import 'package:cineart/services/movie_action_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_storage_service.dart';


void main() {
  late MovieActionService service;

  setUp(() {
    final fakeStorage = FakeStorageService();
    service = MovieActionService.withStorage(fakeStorage);
    service.setUser('test@example.com');
  });

  group('MovieActionService - rateMovie', () {
    test('crée une nouvelle action avec rating', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 9.0);
      final action = service.getAction(1);
      expect(action, isNotNull);
      expect(action!.rating, 9.0);
      expect(action.movieTitle, 'Inception');
    });

    test('met à jour le rating si film déjà noté', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 7.0);
      service.rateMovie(1, 'Inception', '/inc.jpg', 9.0);
      expect(service.getAction(1)!.rating, 9.0);
    });

    test('enregistre la review si fournie', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 8.0, review: 'Super film');
      expect(service.getAction(1)!.review, 'Super film');
    });

    test('trim la review', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 8.0, review: '  Top  ');
      expect(service.getAction(1)!.review, 'Top');
    });

    test('review vide stockée comme null', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 8.0, review: '   ');
      expect(service.getAction(1)!.review, isNull);
    });

    test('enregistre genres, directors, topActors', () {
      final directors = [CrewMember(id: 1, name: 'Nolan', job: 'Director')];
      final cast = [
        CastMember(id: 1, name: 'Bale', character: 'Batman', profilePath: ''),
        CastMember(id: 2, name: 'Caine', character: 'Alfred', profilePath: ''),
      ];
      service.rateMovie(1, 'Batman', '/bat.jpg', 9.0,
          genres: ['Action', 'Drame'], directors: directors, cast: cast);
      final action = service.getAction(1)!;
      expect(action.genres, ['Action', 'Drame']);
      expect(action.directors, ['Nolan']);
      expect(action.topActors, containsAll(['Bale', 'Caine']));
    });
  });

  group('MovieActionService - removeRating', () {
    test('supprime le rating', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 8.0);
      service.removeRating(1);
      expect(service.getAction(1)?.rating, isNull);
    });

    test('supprime l\'action si pas de watchLater', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 8.0);
      service.removeRating(1);
      expect(service.getAction(1), isNull);
    });

    test('garde l\'action si watchLater est true', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 8.0);
      service.toggleWatchLater(1, 'Inception', '/inc.jpg');
      service.removeRating(1);
      expect(service.getAction(1), isNotNull);
      expect(service.getAction(1)!.watchLater, isTrue);
    });
  });

  group('MovieActionService - review', () {
    setUp(() => service.rateMovie(1, 'Inception', '/inc.jpg', 8.0));

    test('setReview met à jour la review', () {
      service.setReview(1, 'Excellent');
      expect(service.getAction(1)!.review, 'Excellent');
    });

    test('setReview avec texte vide efface la review', () {
      service.setReview(1, 'Excellent');
      service.setReview(1, '   ');
      expect(service.getAction(1)!.review, isNull);
    });

    test('removeReview efface la review', () {
      service.setReview(1, 'Excellent');
      service.removeReview(1);
      expect(service.getAction(1)!.review, isNull);
    });

    test('setReview sans rating préalable ne fait rien', () {
      service.setReview(99, 'Review orpheline');
      expect(service.getAction(99), isNull);
    });
  });

  group('MovieActionService - watchLater', () {
    test('toggleWatchLater ajoute à la liste', () {
      service.toggleWatchLater(2, 'Dune', '/dune.jpg');
      expect(service.getAction(2)!.watchLater, isTrue);
    });

    test('toggleWatchLater retire de la liste', () {
      service.toggleWatchLater(2, 'Dune', '/dune.jpg');
      service.toggleWatchLater(2, 'Dune', '/dune.jpg');
      expect(service.getAction(2), isNull);
    });

    test('getWatchLaterList retourne les bons films', () {
      service.toggleWatchLater(2, 'Dune', '/dune.jpg');
      service.toggleWatchLater(3, 'Tenet', '/tenet.jpg');
      expect(service.getWatchLaterList().length, 2);
    });
  });

  group('MovieActionService - quiz / trophées', () {
    test('saveQuizResult crée une action avec trophée', () {
      service.saveQuizResult(1, 'Inception', '/inc.jpg', TrophyLevel.gold);
      final action = service.getAction(1)!;
      expect(action.quizCompleted, isTrue);
      expect(action.trophy, TrophyLevel.gold);
    });

    test('saveQuizResult met à jour l\'action existante', () {
      service.rateMovie(1, 'Inception', '/inc.jpg', 8.0);
      service.saveQuizResult(1, 'Inception', '/inc.jpg', TrophyLevel.platinum);
      expect(service.getAction(1)!.trophy, TrophyLevel.platinum);
      expect(service.getAction(1)!.rating, 8.0);
    });

    test('saveQuizResult avec trophy null — quizCompleted reste true', () {
      service.saveQuizResult(1, 'Inception', '/inc.jpg', null);
      expect(service.getAction(1)!.quizCompleted, isTrue);
      expect(service.getAction(1)!.trophy, isNull);
    });

    test('getTrophies retourne uniquement les actions avec trophée', () {
      service.saveQuizResult(1, 'Inception', '/inc.jpg', TrophyLevel.gold);
      service.saveQuizResult(2, 'Tenet', '/tenet.jpg', null);
      expect(service.getTrophies().length, 1);
      expect(service.getTrophies().first.trophy, TrophyLevel.gold);
    });
  });

  group('MovieActionService - stats par année', () {
    setUp(() {
      service.rateMovie(1, 'Film A', '/a.jpg', 8.0,
          genres: ['Action'], directors: [CrewMember(id: 1, name: 'Nolan', job: 'Director')],
          cast: [CastMember(id: 1, name: 'Bale', character: 'Hero', profilePath: '')]);
      service.rateMovie(2, 'Film B', '/b.jpg', 6.0,
          genres: ['Action', 'Drame'], directors: [CrewMember(id: 1, name: 'Nolan', job: 'Director')],
          cast: [CastMember(id: 2, name: 'Hardy', character: 'Villain', profilePath: '')]);
      service.rateMovie(3, 'Film C', '/c.jpg', 4.0,
          genres: ['Horreur'], directors: [CrewMember(id: 2, name: 'Villeneuve', job: 'Director')],
          cast: [CastMember(id: 1, name: 'Bale', character: 'Hero2', profilePath: '')]);
    });

    test('getRatedMovies retourne tous les films notés', () {
      expect(service.getRatedMovies().length, 3);
    });

    test('getAverageRatingForYear calcule la moyenne', () {
      final year = DateTime.now().year;
      final avg = service.getAverageRatingForYear(year);
      expect(avg, closeTo(6.0, 0.1));
    });

    test('getMostWatchedGenreForYear retourne le genre dominant', () {
      final year = DateTime.now().year;
      expect(service.getMostWatchedGenreForYear(year), 'Action');
    });

    test('getMostWatchedDirectorForYear retourne le réalisateur dominant', () {
      final year = DateTime.now().year;
      expect(service.getMostWatchedDirectorForYear(year), 'Nolan');
    });

    test('getMostWatchedActorForYear retourne l\'acteur dominant', () {
      final year = DateTime.now().year;
      expect(service.getMostWatchedActorForYear(year), 'Bale');
    });

    test('getRatingDistributionForYear compte correctement', () {
      final year = DateTime.now().year;
      final dist = service.getRatingDistributionForYear(year);
      expect(dist[8], 1);
      expect(dist[6], 1);
      expect(dist[4], 1);
    });

    test('retourne null si aucun film pour l\'année', () {
      expect(service.getMostWatchedGenreForYear(1900), isNull);
      expect(service.getMostWatchedDirectorForYear(1900), isNull);
      expect(service.getMostWatchedActorForYear(1900), isNull);
    });
  });

  group('MovieActionService - setUser / clearUser', () {
    test('lance StateError si pas de user set', () {
      final s = MovieActionService.withStorage(FakeStorageService());
      expect(() => s.getAction(1), throwsStateError);
    });

    test('clearUser puis getAction → StateError', () {
      service.clearUser();
      expect(() => service.getAction(1), throwsStateError);
    });

    test('2 users ont des storages séparés', () {
      service.setUser('user1@example.com');
      service.rateMovie(1, 'Film', '/f.jpg', 9.0);

      service.setUser('user2@example.com');
      expect(service.getAction(1), isNull);
    });
  });
}