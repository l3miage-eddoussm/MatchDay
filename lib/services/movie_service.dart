import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

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
    final List results = data['results'];
    return results.map((e) => Movie.fromJson(e)).toList();
  }
}