import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/movie_detail.dart';

class MovieService {
  static final MovieService _instance = MovieService._internal();

  factory MovieService() => _instance;

  MovieService._internal();

  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _token =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIzNDkyZTZiNjZhOTI0ODNjMmY5YWJmNDAwNTFmODMzOSIsIm5iZiI6MTc3Njk0ODA4OC4zMzcsInN1YiI6IjY5ZWExMzc4NDQwMWM5OTc4M2JiMWUwNiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.nyKxwD7R4acO09pye2wAfNQ8nQbKhZ7pYbv72l3blrY';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  Future<List<Movie>> getTrendingMovies() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/trending/movie/week?language=fr-FR'),
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
      Uri.parse('$_baseUrl/movie/$movieId?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les détails du film.');
    }
    return Movie.fromJson(jsonDecode(response.body));
  }

  Future<List<MovieVideo>> getMovieVideos(int movieId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/$movieId/videos?language=fr-FR'),
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
      Uri.parse('$_baseUrl/movie/$movieId/images'),
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
      Uri.parse('$_baseUrl/movie/$movieId/credits?language=fr-FR'),
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
      Uri.parse('$_baseUrl/movie/$movieId/similar?language=fr-FR'),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return (data['results'] as List)
        .take(10)
        .map((e) => Movie.fromJson(e))
        .toList();
  }
}