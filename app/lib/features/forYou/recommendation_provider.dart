import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../search/search_providers.dart' show apiProvider;
import '../storage/app_db.dart';

class RecommendationData {
  const RecommendationData({
    required this.tracks,
    required this.excludeCount,
  });

  final List<Track> tracks;
  final int excludeCount;

  bool get isEmpty => tracks.isEmpty;
}

final recommendationProvider = FutureProvider.autoDispose<RecommendationData>((ref) async {
  final db = ref.watch(dbProvider);
  final api = ref.watch(apiProvider);

  final top = await db.topPlays(limit: 8);
  final recent = await db.recentPlays(limit: 8);
  final all = <Track>[...top, ...recent];

  final seedArtists = <String>{};
  final seedTracks = <({String artist, String title})>[];
  final excludeIds = <String>{};

  for (final t in all) {
    excludeIds.add(t.id);
    if (t.artist.isNotEmpty && t.artist != t.uploader) {
      seedArtists.add(t.artist);
    }
    if (t.title.isNotEmpty) {
      seedTracks.add((artist: t.artist, title: t.title));
    }
  }

  if (seedArtists.isEmpty && seedTracks.isEmpty) {
    return const RecommendationData(tracks: [], excludeCount: 0);
  }

  final seedList = seedArtists.take(3).toList();

  final tracks = await api.recommendations(
    seeds: seedList,
    seedTracks: seedTracks.take(6).toList(),
    excludeIds: excludeIds.toList(),
    limit: 13,
  );

  return RecommendationData(
    tracks: tracks,
    excludeCount: excludeIds.length,
  );
});
