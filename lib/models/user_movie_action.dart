class UserMovieAction {
  final int movieId;
  final String movieTitle;
  final String posterPath;
  final double? rating;
  final bool watchLater;
  final String? review;

  static const _undefined = Object();

  UserMovieAction({
    required this.movieId,
    required this.movieTitle,
    required this.posterPath,
    this.rating,
    this.watchLater = false,
    this.review,
  });

  factory UserMovieAction.fromJson(Map<String, dynamic> json) =>
      UserMovieAction(
        movieId: json['movieId'],
        movieTitle: json['movieTitle'] ?? '',
        posterPath: json['posterPath'] ?? '',
        rating: json['rating'] != null
            ? (json['rating'] as num).toDouble()
            : null,
        watchLater: json['watchLater'] ?? false,
        review: json['review'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'movieTitle': movieTitle,
    'posterPath': posterPath,
    'rating': rating,
    'watchLater': watchLater,
    'review': review,
  };

  UserMovieAction copyWith({
    Object? rating = _undefined,
    bool? watchLater,
    Object? review = _undefined,
  }) =>
      UserMovieAction(
        movieId: movieId,
        movieTitle: movieTitle,
        posterPath: posterPath,
        rating: identical(rating, _undefined) ? this.rating : rating as double?,
        watchLater: watchLater ?? this.watchLater,
        review: identical(review, _undefined) ? this.review : review as String?,
      );

  bool get hasReview => review != null && review!.trim().isNotEmpty;
}