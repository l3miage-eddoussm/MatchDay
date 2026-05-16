class MovieVideo {
  final String key;
  final String name;
  final String site;
  final String type;

  MovieVideo({
    required this.key,
    required this.name,
    required this.site,
    required this.type,
  });

  factory MovieVideo.fromJson(Map<String, dynamic> json) => MovieVideo(
    key: json['key'] ?? '',
    name: json['name'] ?? '',
    site: json['site'] ?? '',
    type: json['type'] ?? '',
  );

  String get thumbnailUrl => 'https://img.youtube.com/vi/$key/hqdefault.jpg';
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$key';
}

class MovieImage {
  final String filePath;

  MovieImage({required this.filePath});

  factory MovieImage.fromJson(Map<String, dynamic> json) =>
      MovieImage(filePath: json['file_path'] ?? '');

  String get imageUrl => 'https://image.tmdb.org/t/p/w780$filePath';
}

class CastMember {
  final int id;
  final String name;
  final String character;
  final String profilePath;

  CastMember({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    character: json['character'] ?? '',
    profilePath: json['profile_path'] ?? '',
  );

  String get profileUrl => 'https://image.tmdb.org/t/p/w185$profilePath';
}

class CrewMember {
  final int id;
  final String name;
  final String job;

  CrewMember({required this.id,required this.name, required this.job});

  factory CrewMember.fromJson(Map<String, dynamic> json) => CrewMember(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    job: json['job'] ?? '',
  );
}