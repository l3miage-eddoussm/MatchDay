import 'movie_detail.dart';

class MovieCredits {
  final List<CastMember> cast;
  final List<CrewMember> directors;

  const MovieCredits({
    required this.cast,
    required this.directors,
  });
}