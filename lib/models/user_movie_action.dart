class UserMovieAction {
  final int movieId;
  final String movieTitle;
  final String posterPath;
  final double? rating;
  final bool watchLater;
  final String? review;
  final bool quizCompleted;
  final TrophyLevel? trophy;

  static const _undefined = Object();

  UserMovieAction({
    required this.movieId,
    required this.movieTitle,
    required this.posterPath,
    this.rating,
    this.watchLater = false,
    this.review,
    this.quizCompleted = false,
    this.trophy,
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
        quizCompleted: json['quizCompleted'] ?? false,
        trophy: json['trophy'] != null
            ? TrophyLevel.values.firstWhere(
              (e) => e.name == json['trophy'],
          orElse: () => TrophyLevel.bronze,
        )
            : null,
      );

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'movieTitle': movieTitle,
    'posterPath': posterPath,
    'rating': rating,
    'watchLater': watchLater,
    'review': review,
    'quizCompleted': quizCompleted,
    'trophy': trophy?.name,
  };

  UserMovieAction copyWith({
    Object? rating = _undefined,
    bool? watchLater,
    Object? review = _undefined,
    bool? quizCompleted,
    Object? trophy = _undefined,
  }) =>
      UserMovieAction(
        movieId: movieId,
        movieTitle: movieTitle,
        posterPath: posterPath,
        rating: identical(rating, _undefined) ? this.rating : rating as double?,
        watchLater: watchLater ?? this.watchLater,
        review: identical(review, _undefined) ? this.review : review as String?,
        quizCompleted: quizCompleted ?? this.quizCompleted,
        trophy: identical(trophy, _undefined)
            ? this.trophy
            : trophy as TrophyLevel?,
      );

  bool get hasReview => review != null && review!.trim().isNotEmpty;
}

enum TrophyLevel { bronze, silver, gold, platinum }

extension TrophyLevelExtension on TrophyLevel {
  String get label {
    switch (this) {
      case TrophyLevel.bronze:
        return 'Bronze';
      case TrophyLevel.silver:
        return 'Argent';
      case TrophyLevel.gold:
        return 'Or';
      case TrophyLevel.platinum:
        return 'Platine';
    }
  }

  String get emoji {
    switch (this) {
      case TrophyLevel.bronze:
        return '🥉';
      case TrophyLevel.silver:
        return '🥈';
      case TrophyLevel.gold:
        return '🥇';
      case TrophyLevel.platinum:
        return '💎';
    }
  }

  int get color {
    switch (this) {
      case TrophyLevel.bronze:
        return 0xFFCD7F32;
      case TrophyLevel.silver:
        return 0xFFC0C0C0;
      case TrophyLevel.gold:
        return 0xFFFFD700;
      case TrophyLevel.platinum:
        return 0xFF00E5FF;
    }
  }
}

TrophyLevel? trophyFromScore(int score) {
  if (score >= 10) return TrophyLevel.platinum;
  if (score >= 7) return TrophyLevel.gold;
  if (score >= 5) return TrophyLevel.silver;
  if (score >= 3) return TrophyLevel.bronze;
  return null;
}