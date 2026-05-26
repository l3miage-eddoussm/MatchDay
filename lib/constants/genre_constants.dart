import '../models/genre.dart';

abstract final class GenreConstants {
  static const List<Genre> genres = [
    Genre(id: 28,    name: 'Action'),
    Genre(id: 35,    name: 'Comédie'),
    Genre(id: 27,    name: 'Horreur'),
    Genre(id: 878,   name: 'Science-Fiction'),
    Genre(id: 16,    name: 'Animation'),
    Genre(id: 53,    name: 'Thriller'),
    Genre(id: 10749, name: 'Romance'),
    Genre(id: 99,    name: 'Documentaire'),
  ];
}