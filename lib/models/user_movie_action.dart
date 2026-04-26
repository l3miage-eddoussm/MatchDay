class UserMovieAction {
  final int movieId;
  final String movieTitle;
  final String posterPath;
  final double? rating;
  final bool watchLater;
  static const _undefined = Object();

  UserMovieAction({
    required this.movieId,
    required this.movieTitle,
    required this.posterPath,
    this.rating,
    this.watchLater = false,
  });

  factory UserMovieAction.fromJson(Map<String, dynamic> json) => UserMovieAction(
    movieId: json['movieId'],
    movieTitle: json['movieTitle'] ?? '',
    posterPath: json['posterPath'] ?? '',
    rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    watchLater: json['watchLater'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'movieTitle': movieTitle,
    'posterPath': posterPath,
    'rating': rating,
    'watchLater': watchLater,
  };

  UserMovieAction copyWith({
    Object? rating = _undefined,
    bool? watchLater,
  }) =>
      UserMovieAction(
        movieId: movieId,
        movieTitle: movieTitle,
        posterPath: posterPath,
        rating: identical(rating, _undefined) ? this.rating : rating as double?,
        watchLater: watchLater ?? this.watchLater,
      );
}