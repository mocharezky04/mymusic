import 'package:flutter_test/flutter_test.dart';

import 'package:mymusic/core/models.dart';

void main() {
  group('Track.fromJson', () {
    test('maps fields and source', () {
      final track = Track.fromJson({
        'id': 'abc123',
        'source': 'ytmusic',
        'title': 'Judul Lagu',
        'artist': 'Artis',
        'duration': 217,
        'thumb': 'https://example.com/art.jpg',
        'uploader': 'Artis',
        'url': 'https://music.youtube.com/watch?v=abc123',
      });

      expect(track.id, 'abc123');
      expect(track.source, TrackSource.ytmusic);
      expect(track.source.playable, isTrue);
      expect(track.durationLabel, '3:37');
    });

    test('falls back to youtube source and empty fields', () {
      final track = Track.fromJson({'id': 'x', 'source': 'unknown'});

      expect(track.source, TrackSource.youtube);
      expect(track.title, '');
      expect(track.uploader, '');
      expect(track.durationLabel, '');
    });

    test('spotify is not playable', () {
      final track = Track.fromJson({'id': 'x', 'source': 'spotify'});
      expect(track.source.playable, isFalse);
    });
  });
}