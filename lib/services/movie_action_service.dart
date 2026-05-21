import 'dart:convert';
import '../models/user_movie_action.dart';
import 'storage_service.dart';

class MovieActionService {
  static final MovieActionService _instance = MovieActionService._internal();

  factory MovieActionService() => _instance;

  MovieActionService._internal();

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
    final raw = StorageService().getItem(_storageKey);
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
    StorageService().setItem(_storageKey, encoded);
  }

  UserMovieAction? getAction(int movieId) => _getAll()[movieId];

  void rateMovie(
      int movieId,
      String title,
      String posterPath,
      double rating, {
        String? review,
      }) {
    final all = _getAll();
    final existing = all[movieId];
    final trimmed =
    (review != null && review.trim().isNotEmpty) ? review.trim() : null;
    all[movieId] = existing != null
        ? existing.copyWith(
      rating: rating,
      review: trimmed ?? existing.review,
    )
        : UserMovieAction(
      movieId: movieId,
      movieTitle: title,
      posterPath: posterPath,
      rating: rating,
      review: trimmed,
    );
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

  List<UserMovieAction> getWatchLaterList() =>
      _getAll().values.where((a) => a.watchLater).toList();

  List<UserMovieAction> getRatedMovies() =>
      _getAll().values.where((a) => a.rating != null).toList();
}