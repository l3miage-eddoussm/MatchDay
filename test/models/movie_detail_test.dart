import 'package:cineart/models/movie_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CastMember', () {
    final json = {
      'id': 1,
      'name': 'Christian Bale',
      'character': 'Bruce Wayne',
      'profile_path': '/bale.jpg',
    };

    test('fromJson parse correctement', () {
      final cast = CastMember.fromJson(json);
      expect(cast.name, 'Christian Bale');
      expect(cast.character, 'Bruce Wayne');
    });

    test('profileUrl construit la bonne URL', () {
      final cast = CastMember.fromJson(json);
      expect(cast.profileUrl, 'https://image.tmdb.org/t/p/w185/bale.jpg');
    });

    test('fromJson avec champs manquants retourne des defaults', () {
      final cast = CastMember.fromJson({});
      expect(cast.id, 0);
      expect(cast.name, '');
      expect(cast.character, '');
    });
  });

  group('MovieVideo', () {
    final json = {
      'key': 'abc123',
      'name': 'Trailer officiel',
      'site': 'YouTube',
      'type': 'Trailer',
    };

    test('fromJson parse correctement', () {
      final video = MovieVideo.fromJson(json);
      expect(video.key, 'abc123');
      expect(video.site, 'YouTube');
    });

    test('thumbnailUrl construit la bonne URL', () {
      final video = MovieVideo.fromJson(json);
      expect(video.thumbnailUrl, 'https://img.youtube.com/vi/abc123/hqdefault.jpg');
    });

    test('youtubeUrl construit la bonne URL', () {
      final video = MovieVideo.fromJson(json);
      expect(video.youtubeUrl, 'https://www.youtube.com/watch?v=abc123');
    });
  });

  group('MovieImage', () {
    test('imageUrl construit la bonne URL', () {
      final image = MovieImage.fromJson({'file_path': '/img.jpg'});
      expect(image.imageUrl, 'https://image.tmdb.org/t/p/w780/img.jpg');
    });
  });
}