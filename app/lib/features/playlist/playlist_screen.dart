import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets/state_shell.dart';
import '../player/player_provider.dart';
import '../storage/app_db.dart';
import 'add_to_playlist_sheet.dart';
import 'playlist_detail_screen.dart';
import 'playlist_providers.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.playlistSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.newPlaylist),
              ),
            ],
          ),
        ),
        Expanded(
          child: ref
              .watch(playlistsProvider)
              .when(
                loading: () => StateLoading(
                  title: l10n.loadPlaylistsLoading,
                  subtitle: l10n.loadPlaylistHint,
                ),
                error: (err, _) => StateMessage(
                  icon: Icons.error_outline_rounded,
                  title: l10n.loadPlaylistsFailed,
                  subtitle: l10n.loadPlaylistHint,
                  action: TextButton.icon(
                    onPressed: () => ref.invalidate(playlistsProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l10n.tryAgain),
                  ),
                ),
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return StateMessage(
                      icon: Icons.queue_music_outlined,
                      title: l10n.emptyPlaylistsTitle,
                      subtitle: l10n.emptyPlaylistsSubtitle,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: playlists.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final pl = playlists[index];
                      return _PlaylistTile(playlist: pl);
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(l10nProvider);
    final name = await askPlaylistName(context, l10n);
    if (name == null || !context.mounted) return;
    await ref.read(playlistsProvider.notifier).create(name);
  }
}

class _PlaylistTile extends ConsumerWidget {
  const _PlaylistTile({required this.playlist});

  final PlaylistRow playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    final tracks =
        ref.watch(playlistTracksProvider(playlist.id)).value ?? const [];
    final controller = ref.read(playerControllerProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlaylistDetailScreen(playlist: playlist),
            ),
          );
        },
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            Icons.library_music_outlined,
            size: 26,
            color: scheme.primary,
          ),
        ),
        title: Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(l10n.trackCount(tracks.length)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tracks.isNotEmpty)
              IconButton(
                onPressed: () => controller.playFrom(tracks, 0),
                icon: Icon(Icons.play_arrow_rounded, color: scheme.primary),
                tooltip: l10n.playAllLabel,
              ),
            PopupMenuButton<String>(
              tooltip: l10n.moreActions,
              onSelected: (action) {
                switch (action) {
                  case 'rename':
                    _rename(context, ref);
                  case 'delete':
                    _delete(context, ref);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rename',
                  height: 44,
                  child: _MenuRow(Icons.edit_rounded, l10n.rename),
                ),
                PopupMenuItem(
                  value: 'delete',
                  height: 44,
                  child: _MenuRow(Icons.delete_outline_rounded, l10n.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(l10nProvider);
    final name = await askPlaylistName(context, l10n, initial: playlist.name);
    if (name == null) return;
    await ref.read(playlistsProvider.notifier).rename(playlist.id, name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(l10nProvider);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlaylistTitle),
        content: Text(l10n.deletePlaylistConfirm(playlist.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(playlistsProvider.notifier).delete(playlist.id);
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.playlistDeleted)));
    }
  }
}

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
