import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';

class MovieService {
  static final MovieService _instance = MovieService._internal();

  factory MovieService() => _instance;

  MovieService._internal();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AppConstants.tmdbToken}',
    'Content-Type': 'application/json',
  };

  Future<List<Movie>> getTrendingMovies() async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/trending/movie/week?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les films tendance.');
    }
    final data = jsonDecode(response.body);
    return (data['results'] as List).map((e) => Movie.fromJson(e)).toList();
  }

  Future<Movie> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/$movieId?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les détails du film.');
    }
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

  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/$movieId/credits?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) return {'cast': [], 'crew': []};
    final data = jsonDecode(response.body);
    final cast = (data['cast'] as List)
        .take(10)
        .map((e) => CastMember.fromJson(e))
        .toList();
    final crew = (data['crew'] as List)
        .map((e) => CrewMember.fromJson(e))
        .where((c) => c.job == 'Director')
        .toList();
    return {'cast': cast, 'crew': crew};
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

  Future<List<Movie>> getNowPlayingMovies() async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/now_playing?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Impossible de charger les films.');
    final data = jsonDecode(response.body);
    return (data['results'] as List).map((e) => Movie.fromJson(e)).toList();
  }

  Future<List<Movie>> getTopRatedMovies() async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/top_rated?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Impossible de charger les films.');
    final data = jsonDecode(response.body);
    return (data['results'] as List).map((e) => Movie.fromJson(e)).toList();
  }

  Future<List<Movie>> getUpcomingMovies() async {
    final response = await http.get(
      Uri.parse('${AppConstants.tmdbBaseUrl}/movie/upcoming?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Impossible de charger les films.');
    final data = jsonDecode(response.body);
    return (data['results'] as List).map((e) => Movie.fromJson(e)).toList();
  }

  Future<List<Movie>> getMoviesByGenre(int genreId) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.tmdbBaseUrl}/discover/movie?language=fr-FR&with_genres=$genreId&sort_by=popularity.desc',
      ),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return (data['results'] as List).map((e) => Movie.fromJson(e)).toList();
  }
}