import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../storage/app_db.dart';
import 'playlist_providers.dart';

Future<void> pickPlaylistForTrack(BuildContext context, Track track) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PickPlaylistSheet(track: track),
  );
}

class AddToPlaylistIconButton extends ConsumerWidget {
  const AddToPlaylistIconButton({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => pickPlaylistForTrack(context, track),
      icon: const Icon(Icons.playlist_add_rounded, size: 20),
      tooltip: ref.watch(l10nProvider).addToPlaylist,
    );
  }
}

class _PickPlaylistSheet extends ConsumerWidget {
  const _PickPlaylistSheet({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final scheme = Theme.of(context).colorScheme;
    final playlists = ref.watch(playlistsProvider);
    final messenger = ScaffoldMessenger.of(context);

    Future<bool> addTo(int id, String name) async {
      await ref.read(dbProvider).addTrackToPlaylist(id, track);
      ref.invalidate(playlistTracksProvider(id));
      return true;
    }

    void notify(String name) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.addedToPlaylist(name))),
      );
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Icon(
                  Icons.playlist_add_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.pickPlaylistTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final name = await askPlaylistName(context, l10n);
                  if (name == null || !context.mounted) return;
                  final id = await ref
                      .read(playlistsProvider.notifier)
                      .create(name);
                  await addTo(id, name);
                  if (context.mounted) notify(name);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.newPlaylist),
              ),
            ),
          ),
          Flexible(
            child: playlists.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 240,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.loadPlaylistsLoading,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.playlistsUnavailable,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: scheme.error),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.pickPlaylistEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final pl = list[i];
                    return _PlaylistRow(
                      playlist: pl,
                      track: track,
                      onTap: () async {
                        final added = await addTo(pl.id, pl.name);
                        if (added && context.mounted) notify(pl.name);
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PlaylistRow extends ConsumerWidget {
  const _PlaylistRow({
    required this.playlist,
    required this.track,
    required this.onTap,
  });

  final PlaylistRow playlist;
  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    final tracks =
        ref.watch(playlistTracksProvider(playlist.id)).value ?? const <Track>[];
    final alreadyAdded = tracks.any(
      (t) => t.id == track.id && t.source == track.source,
    );

    return ListTile(
      dense: true,
      onTap: onTap,
      enabled: !alreadyAdded,
      leading: Icon(
        Icons.playlist_play_rounded,
        color: alreadyAdded ? scheme.outline : scheme.primary,
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        alreadyAdded ? l10n.alreadyInPlaylists : l10n.trackCount(tracks.length),
      ),
      trailing: Icon(
        alreadyAdded ? Icons.check_circle_rounded : Icons.playlist_add_rounded,
        color: alreadyAdded ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}

Future<String?> askPlaylistName(
  BuildContext context,
  L10n l10n, {
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);
  final messenger = ScaffoldMessenger.of(context);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      String? value = initial;
      return AlertDialog(
        title: Text(l10n.createPlaylistTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.playlistNameHint,
            labelText: l10n.playlistName,
          ),
          onChanged: (v) => value = v,
          onSubmitted: (v) {
            if (v.trim().isEmpty) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.playlistEmptyName)),
              );
              return;
            }
            Navigator.of(ctx).pop(v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = value ?? controller.text;
              if (v.trim().isEmpty) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.playlistEmptyName)),
                );
                return;
              }
              Navigator.of(ctx).pop(v.trim());
            },
            child: Text(l10n.create),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}
