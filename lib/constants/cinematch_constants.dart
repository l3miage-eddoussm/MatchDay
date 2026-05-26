abstract final class CineMatchConstants {
  static const int maxRandomPage         = 8;
  static const int fallbackMaxRandomPage = 5;
  static const int maxPickIndex          = 15;
  static const int minVoteCount          = 200;
  static const int fallbackMinVoteCount  = 100;
  static const int fallbackGenreId       = 18;

  static const Map<String, List<int>> moodGenres = {
    'fun':    [35],
    'scared': [27, 53],
    'think':  [18, 9648],
    'sad':    [18, 10749],
    'thrill': [28, 80],
    'escape': [12, 14],
  };

  static const Map<String, double> moodMinRating = {
    'fun':    6.5,
    'scared': 6.0,
    'think':  7.0,
    'sad':    6.5,
    'thrill': 6.5,
    'escape': 6.5,
  };

  static const Map<String, List<int>> styleGenres = {
    'realistic':  [18, 36],
    'fantasy':    [14, 878, 16],
    'true_story': [36, 99],
    'any':        [],
  };

  static const Map<String, List<int>> audienceExcludedGenres = {
    'famille': [27, 53, 80, 9648],
    'couple':  [],
    'amis':    [],
    'solo':    [],
  };

  static const Map<String, int> audienceBonusGenre = {
    'famille': 16,
    'couple':  10749,
    'amis':    35,
    'solo':    0,
  };
}