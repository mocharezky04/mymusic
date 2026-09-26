import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/widgets/state_shell.dart';
import '../player/player_provider.dart';
import '../search/track_tile.dart';
import '../storage/app_db.dart';
import 'add_to_playlist_sheet.dart';
import 'playlist_providers.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});

  final PlaylistRow playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final tracks = ref.watch(playlistTracksProvider(playlist.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            tooltip: l10n.rename,
            onPressed: () => _rename(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: tracks.when(
        loading: () => StateLoading(title: l10n.loadSongsLoading),
        error: (err, _) => StateMessage(
          icon: Icons.error_outline_rounded,
          title: l10n.loadPlaylistsFailed,
          subtitle: l10n.loadPlaylistHint,
          action: TextButton.icon(
            onPressed: () =>
                ref.invalidate(playlistTracksProvider(playlist.id)),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.tryAgain),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return StateMessage(
              icon: Icons.music_off_rounded,
              title: l10n.noSongsTitle,
              subtitle: l10n.noSongsSubtitle,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: [
                    Text(
                      l10n.trackCount(list.length).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => controller.playFrom(list, 0),
                      icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 19,
                      ),
                      label: Text(l10n.playAllLabel),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _playShuffled(context, ref, list),
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: Text(l10n.shufflePlay),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  buildDefaultDragHandles: false,
                  itemCount: list.length,
                  onReorderItem: (oldIndex, newIndex) async {
                    await ref
                        .read(dbProvider)
                        .reorderPlaylistTracks(playlist.id, oldIndex, newIndex);
                    ref.invalidate(playlistTracksProvider(playlist.id));
                  },
                  itemBuilder: (context, index) {
                    final track = list[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey('${track.id}-${track.source.apiValue}'),
                      index: index,
                      child: TrackTile(
                        track: track,
                        onTap: () => controller.playFrom(list, index),
                        trailing: PopupMenuButton<_TrackAction>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          tooltip: l10n.moreActions,
                          onSelected: (action) {
                            switch (action) {
                              case _TrackAction.playNext:
                                controller.playNext(track);
                              case _TrackAction.enqueue:
                                controller.addToQueue(track);
                              case _TrackAction.remove:
                                _remove(context, ref, track);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: _TrackAction.playNext,
                              height: 44,
                              child: _MenuRow(
                                Icons.playlist_add_rounded,
                                l10n.playNext,
                              ),
                            ),
                            PopupMenuItem(
                              value: _TrackAction.enqueue,
                              height: 44,
                              child: _MenuRow(
                                Icons.queue_music_rounded,
                                l10n.addToQueue,
                              ),
                            ),
                            PopupMenuItem(
                              value: _TrackAction.remove,
                              height: 44,
                              child: _MenuRow(
                                Icons.delete_outline_rounded,
                                l10n.removeFromPlaylist,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _playShuffled(
    BuildContext context,
    WidgetRef ref,
    List<Track> tracks,
  ) async {
    final shuffled = List<Track>.of(tracks)..shuffle();
    ref.read(playerControllerProvider.notifier).playFrom(shuffled, 0);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Track track) async {
    final l10n = ref.read(l10nProvider);
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(dbProvider)
        .removeTrackFromPlaylist(playlist.id, track.id, track.source.apiValue);
    ref.invalidate(playlistTracksProvider(playlist.id));
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.removedFromPlaylist)));
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(l10nProvider);
    final messenger = ScaffoldMessenger.of(context);
    final name = await askPlaylistName(context, l10n, initial: playlist.name);
    if (name == null) return;
    await ref.read(playlistsProvider.notifier).rename(playlist.id, name);
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.playlistRenamed)));
    }
  }
}

enum _TrackAction { playNext, enqueue, remove }

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
