class PersonMovie {
  final int id;
  final String title;
  final String posterPath;
  final String releaseDate;
  final double voteAverage;
  final String character;
  final String job;
  final String department;

  PersonMovie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.character,
    required this.job,
    required this.department,
  });

  factory PersonMovie.fromJson(Map<String, dynamic> json) => PersonMovie(
    id: json['id'] ?? 0,
    title: json['title'] ?? json['name'] ?? '',
    posterPath: json['poster_path'] ?? '',
    releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    character: json['character'] ?? '',
    job: json['job'] ?? '',
    department: json['department'] ?? '',
  );

  String get posterUrl => 'https://image.tmdb.org/t/p/w185$posterPath';
  String get year =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
}

class Person {
  final int id;
  final String name;
  final String biography;
  final String profilePath;
  final String birthday;
  final String placeOfBirth;
  final String knownForDepartment;
  final double popularity;
  final List<PersonMovie> actingCredits;
  final List<PersonMovie> directingCredits;

  Person({
    required this.id,
    required this.name,
    required this.biography,
    required this.profilePath,
    required this.birthday,
    required this.placeOfBirth,
    required this.knownForDepartment,
    required this.popularity,
    required this.actingCredits,
    required this.directingCredits,
  });

  factory Person.fromJson(
      Map<String, dynamic> details,
      List<PersonMovie> acting,
      List<PersonMovie> directing,
      ) =>
      Person(
        id: details['id'] ?? 0,
        name: details['name'] ?? '',
        biography: details['biography'] ?? '',
        profilePath: details['profile_path'] ?? '',
        birthday: details['birthday'] ?? '',
        placeOfBirth: details['place_of_birth'] ?? '',
        knownForDepartment: details['known_for_department'] ?? '',
        popularity: (details['popularity'] as num?)?.toDouble() ?? 0.0,
        actingCredits: acting,
        directingCredits: directing,
      );

  String get profileUrl => 'https://image.tmdb.org/t/p/w342$profilePath';

  String get age {
    if (birthday.isEmpty || birthday.length < 4) return '';
    final birth = DateTime.tryParse(birthday);
    if (birth == null) return '';
    final now = DateTime.now();
    int a = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) a--;
    return '$a ans';
  }

  bool get isActor => knownForDepartment == 'Acting';
  bool get isDirector => knownForDepartment == 'Directing';
}