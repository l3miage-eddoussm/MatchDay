import 'package:cineart/models/person.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Person', () {
    final details = {
      'id': 3,
      'name': 'Christopher Nolan',
      'biography': 'Réalisateur britannique.',
      'profile_path': '/nolan.jpg',
      'birthday': '1970-07-30',
      'place_of_birth': 'London, England, UK',
      'known_for_department': 'Directing',
      'popularity': 42.5,
    };

    final person = Person.fromJson(details, [], []);

    test('fromJson parse correctement', () {
      expect(person.name, 'Christopher Nolan');
      expect(person.popularity, 42.5);
      expect(person.knownForDepartment, 'Directing');
    });

    test('isDirector retourne true', () => expect(person.isDirector, isTrue));
    test('isActor retourne false', () => expect(person.isActor, isFalse));

    test('profileUrl construit la bonne URL', () {
      expect(person.profileUrl, 'https://image.tmdb.org/t/p/w342/nolan.jpg');
    });

    test('age calcule correctement', () {
      expect(int.parse(person.age.replaceAll(' ans', '')), greaterThan(50));
    });

    test('age retourne vide si birthday vide', () {
      final p = Person.fromJson({...details, 'birthday': ''}, [], []);
      expect(p.age, '');
    });

    test('shortPlaceOfBirth retourne la valeur complète si <= 24 chars', () {
      expect(person.shortPlaceOfBirth, 'London, England, UK');
      expect(person.shortPlaceOfBirth.endsWith('…'), isFalse);
    });

    test('shortPlaceOfBirth tronque si > 24 chars', () {
      final p = Person.fromJson(
        {...details, 'place_of_birth': 'Los Angeles, California, USA'},
        [], [],
      );
      expect(p.shortPlaceOfBirth.endsWith('…'), isTrue);
      expect(p.shortPlaceOfBirth.length, 25); // 24 chars + '…'
    });
  });

  group('PersonMovie', () {
    final json = {
      'id': 10,
      'title': 'Inception',
      'poster_path': '/inc.jpg',
      'release_date': '2010-07-16',
      'vote_average': 8.8,
      'character': '',
      'job': 'Director',
      'department': 'Directing',
    };

    test('year extrait les 4 premiers chars', () {
      expect(PersonMovie.fromJson(json).year, '2010');
    });

    test('posterUrl construit la bonne URL', () {
      expect(PersonMovie.fromJson(json).posterUrl, 'https://image.tmdb.org/t/p/w185/inc.jpg');
    });

    test('toMovie retourne un Movie valide', () {
      final movie = PersonMovie.fromJson(json).toMovie();
      expect(movie.id, 10);
      expect(movie.title, 'Inception');
    });
  });
}