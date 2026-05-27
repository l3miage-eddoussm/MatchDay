import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../constants/cinematch_constants.dart';
import '../models/cinematch_question.dart';
import '../models/collection_detail.dart';
import '../models/genre.dart';
import '../models/movie.dart';
import '../models/movie_credits.dart';
import '../models/movie_detail.dart';
import '../models/person.dart';
import '../models/search_result.dart';

class MovieService {
  static final MovieService _instance = MovieService._internal();
  factory MovieService() => _instance;
  MovieService._internal();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AppConstants.tmdbToken}',
    'Content-Type': 'application/json',
  };

  Future<List<Movie>> _fetchPaginated(String baseUrl, {int page = 1, int perPage = 10}) async {
    final uri = Uri.parse('$baseUrl${baseUrl.contains('?') ? '&' : '?'}page=$page');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    final results = (data['results'] as List).map((e) => Movie.fromJson(e)).toList();
    final end = perPage < results.length ? perPage : results.length;
    return results.sublist(0, end);
  }

  Future<String?> searchPersonImage(String name) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.tmdbBaseUrl}/search/person?query=${Uri.encodeComponent(name)}',
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode != 200) return null;
      final results = jsonDecode(response.body)['results'] as List;
      if (results.isEmpty) return null;
      final path = results.first['profile_path'];
      if (path == null) return null;
      return '${AppConstants.tmdbImageBaseUrl}/w185$path';
    } catch (_) {
      return null;
    }
  }

  Future<List<Movie>> getTrendingMovies({int page = 1}) =>
      _fetchPaginated('${AppConstants.tmdbBaseUrl}/trending/movie/week?language=fr-FR', page: page);

  Future<List<Movie>> getNowPlayingMovies({int page = 1}) =>
      _fetchPaginated('${AppConstants.tmdbBaseUrl}/movie/now_playing?language=fr-FR', page: page);

  Future<List<Movie>> getTopRatedMovies({int page = 1}) =>
      _fetchPaginated('${AppConstants.tmdbBaseUrl}/movie/top_rated?language=fr-FR', page: page);

  Future<List<Movie>> getUpcomingMovies({int page = 1}) =>
      _fetchPaginated('${AppConstants.tmdbBaseUrl}/movie/upcoming?language=fr-FR', page: page);

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) =>
      _fetchPaginated(
        '${AppConstants.tmdbBaseUrl}/discover/movie?language=fr-FR&with_genres=$genreId&sort_by=popularity.desc',
        page: page,
      );

  Future<Movie> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/$movieId?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Impossible de charger les détails du film.');
    return Movie.fromJson(jsonDecode(response.body));
  }

  Future<List<MovieVideo>> getMovieVideos(int movieId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/$movieId/videos?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return (data['results'] as List)
        .map((e) => MovieVideo.fromJson(e))
        .where((v) => v.site == 'YouTube')
        .toList();
  }

  Future<List<MovieImage>> getMovieImages(int movieId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/$movieId/images'),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return (data['backdrops'] as List? ?? [])
        .take(10)
        .map((e) => MovieImage.fromJson(e))
        .toList();
  }

  Future<MovieCredits> getMovieCredits(int movieId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/$movieId/credits?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) return const MovieCredits(cast: [], directors: []);
    final data = jsonDecode(response.body);
    final cast = (data['cast'] as List)
        .take(10)
        .map((e) => CastMember.fromJson(e))
        .toList();
    final directors = (data['crew'] as List)
        .map((e) => CrewMember.fromJson(e))
        .where((c) => c.job == 'Director')
        .toList();
    return MovieCredits(cast: cast, directors: directors);
  }

  Future<List<Movie>> getSimilarMovies(int movieId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/$movieId/similar?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return (data['results'] as List).take(10).map((e) => Movie.fromJson(e)).toList();
  }

  Future<Person> getPersonDetails(int personId) async {
    final results = await Future.wait([
      http.get(Uri.parse('${AppConstants.tmdbBaseUrl}/person/$personId?language=fr-FR'), headers: _headers),
      http.get(Uri.parse('${AppConstants.tmdbBaseUrl}/person/$personId/movie_credits?language=fr-FR'), headers: _headers),
    ]);
    if (results[0].statusCode != 200) throw Exception('Impossible de charger la personne.');
    final details = jsonDecode(results[0].body) as Map<String, dynamic>;
    List<PersonMovie> acting = [];
    List<PersonMovie> directing = [];
    if (results[1].statusCode == 200) {
      final credits = jsonDecode(results[1].body);
      acting = ((credits['cast'] as List?) ?? [])
          .map((e) => PersonMovie.fromJson(e))
          .where((m) => m.title.isNotEmpty)
          .toList()
        ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      directing = ((credits['crew'] as List?) ?? [])
          .where((e) => e['job'] == 'Director')
          .map((e) => PersonMovie.fromJson(e))
          .where((m) => m.title.isNotEmpty)
          .toList()
        ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    }
    return Person.fromJson(details, acting, directing);
  }

  Future<List<Map<String, dynamic>>> searchPeople(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/search/person?query=${Uri.encodeComponent(query)}&language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['results'] ?? []);
  }

  Future<List<Genre>> getGenres() async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/genre/movie/list?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return (data['genres'] as List)
        .map((e) => Genre.fromJson(e))
        .toList();
  }

  Future<(List<SearchResult>, int)> searchMulti(String query, int page) async {
    final uri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/search/multi'
          '?query=${Uri.encodeComponent(query)}'
          '&page=$page'
          '&language=fr-FR'
          '&include_adult=false',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return (<SearchResult>[], 0);
    final data    = jsonDecode(response.body);
    final results = <SearchResult>[];
    for (final item in data['results'] as List) {
      final type = item['media_type'] as String?;
      if (type == 'movie') {
        final movie = Movie.fromJson(item);
        if (movie.posterPath.isNotEmpty) results.add(MovieResult(movie));
      } else if (type == 'person') {
        final person = SearchPerson.fromJson(item);
        if (person.name.isNotEmpty) results.add(PersonResult(person));
      }
    }
    return (results, data['total_pages'] as int);
  }

  Future<(List<SearchResult>, int)> discoverMovies({
    required int page,
    Set<int> genreIds = const {},
    double minRating = 0.0,
    int? year,
  }) async {
    final buffer = StringBuffer(
      '${AppConstants.tmdbBaseUrl}/discover/movie'
          '?page=$page'
          '&language=fr-FR'
          '&include_adult=false'
          '&sort_by=popularity.desc',
    );
    if (genreIds.isNotEmpty) buffer.write('&with_genres=${genreIds.join(",")}');
    if (minRating > 0) buffer.write('&vote_average.gte=$minRating&vote_count.gte=100');
    if (year != null) buffer.write('&primary_release_year=$year');

    final response = await http.get(Uri.parse(buffer.toString()), headers: _headers);
    if (response.statusCode != 200) return (<SearchResult>[], 0);
    final data    = jsonDecode(response.body);
    final results = (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .where((m) => m.posterPath.isNotEmpty)
        .map((m) => MovieResult(m) as SearchResult)
        .toList();
    return (results, data['total_pages'] as int);
  }

  Future<CollectionDetail> getCollection(int collectionId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/collection/$collectionId?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Impossible de charger la collection.');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final parts = (data['parts'] as List)
        .map((e) => Movie.fromJson(e))
        .toList()
      ..sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
    return CollectionDetail(
      name:         data['name']          ?? '',
      overview:     data['overview']      ?? '',
      backdropPath: data['backdrop_path'] ?? '',
      parts:        parts,
    );
  }

  Future<Movie?> getMovieMatch(Map<CineMatchAnswerKey, String> answers) async {
    final movie = await _fetchMovieMatch(answers, fallback: false);
    if (movie != null) return movie;
    return _fetchMovieMatch(answers, fallback: true);
  }

  Future<Movie?> _fetchMovieMatch(
      Map<CineMatchAnswerKey, String> answers, {
        required bool fallback,
      }) async {
    final mood     = answers[CineMatchAnswerKey.mood]     ?? 'fun';
    final style    = answers[CineMatchAnswerKey.style]    ?? 'any';
    final era      = answers[CineMatchAnswerKey.era]      ?? 'any';
    final duration = answers[CineMatchAnswerKey.duration] ?? 'medium';
    final audience = answers[CineMatchAnswerKey.audience] ?? 'solo';

    final excluded  = List<int>.from(CineMatchConstants.audienceExcludedGenres[audience] ?? []);
    final bonus     = CineMatchConstants.audienceBonusGenre[audience] ?? 0;
    final moodList  = List<int>.from(CineMatchConstants.moodGenres[mood] ?? [CineMatchConstants.fallbackGenreId]);
    final styleList = fallback ? <int>[] : List<int>.from(CineMatchConstants.styleGenres[style] ?? []);

    final genreSet = <int>{
      for (final g in [...moodList, ...styleList])
        if (!excluded.contains(g)) g,
      if (bonus > 0 && !excluded.contains(bonus)) bonus,
    };

    final genreParam = genreSet.isNotEmpty
        ? genreSet.join(',')
        : CineMatchConstants.fallbackGenreId.toString();

    final baseRating = CineMatchConstants.moodMinRating[mood] ?? 6.5;
    final minRating  = fallback
        ? (baseRating - 0.5).clamp(5.0, 9.0)
        : baseRating.clamp(5.0, 9.0);
    final minVotes   = fallback ? CineMatchConstants.fallbackMinVoteCount : CineMatchConstants.minVoteCount;
    final pageRange  = fallback ? CineMatchConstants.fallbackMaxRandomPage : CineMatchConstants.maxRandomPage;

    final params = <String, String>{
      'language':         'fr-FR',
      'sort_by':          'popularity.desc',
      'vote_count.gte':   minVotes.toString(),
      'vote_average.gte': minRating.toStringAsFixed(1),
      'with_genres':      genreParam,
      'page':             (Random().nextInt(pageRange) + 1).toString(),
      ..._eraParams(era),
      ..._durationParams(duration),
      if (audience == 'famille') 'without_genres': '27,53,80,9648',
    };

    final uri = Uri.parse('${AppConstants.tmdbBaseUrl}/discover/movie')
        .replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return null;

    final results = (jsonDecode(response.body)['results'] as List?) ?? [];
    if (results.isEmpty) return null;

    final picked = results[Random().nextInt(
      results.length.clamp(1, CineMatchConstants.maxPickIndex),
    )];
    return Movie.fromJson(picked as Map<String, dynamic>);
  }

  Map<String, String> _eraParams(String era) => switch (era) {
    'recent'  => {'primary_release_date.gte': '2020-01-01'},
    'modern'  => {
      'primary_release_date.gte': '2000-01-01',
      'primary_release_date.lte': '2019-12-31',
    },
    'classic' => {'primary_release_date.lte': '1999-12-31'},
    _         => {},
  };

  Map<String, String> _durationParams(String duration) => switch (duration) {
    'short'  => {'with_runtime.lte': '89'},
    'medium' => {'with_runtime.gte': '90', 'with_runtime.lte': '120'},
    'long'   => {'with_runtime.gte': '121'},
    _        => {},
  };
}