import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/user_movie_action.dart';
import '../models/movie_detail.dart';
import 'storage_service.dart';

class MovieActionService {
  static final MovieActionService _instance = MovieActionService._internal();

  factory MovieActionService() => _instance;

  MovieActionService._internal() : _storage = StorageService();

  final StorageService _storage;

  @visibleForTesting
  MovieActionService.withStorage(this._storage);

  String? _currentUserEmail;

  void setUser(String userEmail) => _currentUserEmail = userEmail;

  void clearUser() => _currentUserEmail = null;

  String get _storageKey {
    if (_currentUserEmail == null) {
      throw StateError('No user set in MovieActionService.');
    }
    return 'movie_actions_user_$_currentUserEmail';
  }

  Map<int, UserMovieAction> _getAll() {
    final raw = _storage.getItem(_storageKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
          (k, v) => MapEntry(int.parse(k), UserMovieAction.fromJson(v)),
    );
  }

  void _saveAll(Map<int, UserMovieAction> actions) {
    final encoded = jsonEncode(
      actions.map((k, v) => MapEntry(k.toString(), v.toJson())),
    );
    _storage.setItem(_storageKey, encoded);
  }

  UserMovieAction? getAction(int movieId) => _getAll()[movieId];

  void rateMovie(
      int movieId,
      String title,
      String posterPath,
      double rating, {
        String? review,
        int? releaseYear,
        List<String> genres = const [],
        List<CrewMember> directors = const [],
        List<CastMember> cast = const [],
      }) {
    final all = _getAll();
    final existing = all[movieId];
    final trimmed =
    (review != null && review.trim().isNotEmpty) ? review.trim() : null;

    final directorNames =
    directors.map((d) => d.name).toList();
    final actorNames =
    cast.take(5).map((c) => c.name).toList();

    if (existing != null) {
      all[movieId] = existing.copyWith(
        rating: rating,
        review: trimmed ?? existing.review,
        ratedAt: existing.ratedAt ?? DateTime.now(),
        releaseYear: existing.releaseYear ?? releaseYear,
        genres: existing.genres.isNotEmpty ? existing.genres : genres,
        directors:
        existing.directors.isNotEmpty ? existing.directors : directorNames,
        topActors:
        existing.topActors.isNotEmpty ? existing.topActors : actorNames,
      );
    } else {
      all[movieId] = UserMovieAction(
        movieId: movieId,
        movieTitle: title,
        posterPath: posterPath,
        rating: rating,
        review: trimmed,
        ratedAt: DateTime.now(),
        releaseYear: releaseYear,
        genres: genres,
        directors: directorNames,
        topActors: actorNames,
      );
    }
    _saveAll(all);
  }

  void setReview(int movieId, String review) {
    final all = _getAll();
    final existing = all[movieId];
    if (existing == null || existing.rating == null) return;
    final trimmed = review.trim();
    all[movieId] = existing.copyWith(
      review: trimmed.isNotEmpty ? trimmed : null,
    );
    _saveAll(all);
  }

  void removeReview(int movieId) {
    final all = _getAll();
    if (!all.containsKey(movieId)) return;
    all[movieId] = all[movieId]!.copyWith(review: null);
    _saveAll(all);
  }

  void removeRating(int movieId) {
    final all = _getAll();
    if (!all.containsKey(movieId)) return;
    all[movieId] = all[movieId]!.copyWith(rating: null, review: null);
    if (!all[movieId]!.watchLater) all.remove(movieId);
    _saveAll(all);
  }

  void toggleWatchLater(int movieId, String title, String posterPath) {
    final all = _getAll();
    final existing = all[movieId];
    if (existing != null) {
      final updated = existing.copyWith(watchLater: !existing.watchLater);
      if (!updated.watchLater && updated.rating == null) {
        all.remove(movieId);
      } else {
        all[movieId] = updated;
      }
    } else {
      all[movieId] = UserMovieAction(
        movieId: movieId,
        movieTitle: title,
        posterPath: posterPath,
        watchLater: true,
      );
    }
    _saveAll(all);
  }

  void saveQuizResult(
      int movieId,
      String title,
      String posterPath,
      TrophyLevel? trophy,
      ) {
    final all = _getAll();
    final existing = all[movieId];
    if (existing != null) {
      all[movieId] = existing.copyWith(
        quizCompleted: true,
        trophy: trophy,
      );
    } else {
      all[movieId] = UserMovieAction(
        movieId: movieId,
        movieTitle: title,
        posterPath: posterPath,
        quizCompleted: true,
        trophy: trophy,
      );
    }
    _saveAll(all);
  }

  List<UserMovieAction> getTrophies() => _getAll()
      .values
      .where((a) => a.quizCompleted && a.trophy != null)
      .toList();

  List<UserMovieAction> getWatchLaterList() =>
      _getAll().values.where((a) => a.watchLater).toList();

  List<UserMovieAction> getRatedMovies() =>
      _getAll().values.where((a) => a.rating != null).toList();

  List<int> getRatedYears() {
    final years = getRatedMovies()
        .map((a) => a.ratedYear)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<UserMovieAction> getRatedMoviesForYear(int year) =>
      getRatedMovies().where((a) => a.ratedYear == year).toList();

  List<UserMovieAction> getTrophiesForYear(int year) =>
      getTrophies().where((a) => a.ratedYear == year).toList();

  String? getMostWatchedActorForYear(int year) {
    final movies = getRatedMoviesForYear(year);
    final count = <String, int>{};
    for (final m in movies) {
      for (final actor in m.topActors) {
        count[actor] = (count[actor] ?? 0) + 1;
      }
    }
    if (count.isEmpty) return null;
    return count.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  String? getMostWatchedDirectorForYear(int year) {
    final movies = getRatedMoviesForYear(year);
    final count = <String, int>{};
    for (final m in movies) {
      for (final dir in m.directors) {
        count[dir] = (count[dir] ?? 0) + 1;
      }
    }
    if (count.isEmpty) return null;
    return count.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  String? getMostWatchedGenreForYear(int year) {
    final movies = getRatedMoviesForYear(year);
    final count = <String, int>{};
    for (final m in movies) {
      for (final genre in m.genres) {
        count[genre] = (count[genre] ?? 0) + 1;
      }
    }
    if (count.isEmpty) return null;
    return count.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  double getAverageRatingForYear(int year) {
    final movies = getRatedMoviesForYear(year);
    if (movies.isEmpty) return 0;
    return movies.fold(0.0, (s, a) => s + (a.rating ?? 0)) / movies.length;
  }

  Map<int, int> getRatingDistributionForYear(int year) {
    final movies = getRatedMoviesForYear(year);
    final dist = <int, int>{};
    for (final m in movies) {
      if (m.rating != null) {
        final r = m.rating!.round();
        dist[r] = (dist[r] ?? 0) + 1;
      }
    }
    return dist;
  }
}