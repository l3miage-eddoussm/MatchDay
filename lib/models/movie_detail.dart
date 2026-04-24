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