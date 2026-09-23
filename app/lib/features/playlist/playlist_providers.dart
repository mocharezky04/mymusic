import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../storage/app_db.dart';

final playlistsProvider =
    AsyncNotifierProvider<PlaylistsController, List<PlaylistRow>>(PlaylistsController.new);

class PlaylistsController extends AsyncNotifier<List<PlaylistRow>> {
  @override
  Future<List<PlaylistRow>> build() {
    final db = ref.watch(dbProvider);
    return db.playlists();
  }

  Future<int> create(String name) async {
    final id = await ref.read(dbProvider).createPlaylist(name);
    ref.invalidateSelf();
    return id;
  }

  Future<void> rename(int id, String name) async {
    await ref.read(dbProvider).renamePlaylist(id, name);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await ref.read(dbProvider).deletePlaylist(id);
    ref.invalidateSelf();
  }
}

final playlistTracksProvider = FutureProvider.family<List<Track>, int>((ref, id) {
  final db = ref.watch(dbProvider);
  return db.playlistTracks(id);
});