import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/widgets/state_shell.dart';
import '../player/player_provider.dart';
import '../playlist/add_to_playlist_sheet.dart';
import '../../core/models.dart';
import 'search_providers.dart';
import 'track_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (value != _query) {
        _query = value;
        ref.read(searchControllerProvider.notifier).run(value);
      }
    });
  }

  void _runNow(String value) {
    _debounce?.cancel();
    _query = value;
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _focus.unfocus();
    ref.read(searchControllerProvider.notifier).run(value);
  }

@override
  Widget build(BuildContext context) {
    final results = ref.watch(searchControllerProvider);
    final l10n = ref.watch(l10nProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _runNow,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _controller.clear();
                        _query = '';
                        ref.read(searchControllerProvider.notifier).clear();
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? _HistoryView(onPick: _runNow)
              : _ResultsView(results: results, query: _query),
        ),
      ],
    );
  }
}

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.results, required this.query});

  final AsyncValue<List<Track>> results;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => StateMessage(
        icon: Icons.cloud_off_rounded,
        title: l10n.searchFailed,
        subtitle: '$err',
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return StateMessage(
            icon: Icons.music_off_rounded,
            title: l10n.searchNoResults,
            subtitle: l10n.searchRetry,
          );
        }
        final currentId = ref.watch(
          playerControllerProvider.select((s) => s.current?.id),
        );
        final playing = ref.watch(
          playerControllerProvider.select((s) => s.playing),
        );
        final controller = ref.read(playerControllerProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultsHeader(
              l10n: l10n,
              count: tracks.length,
              onPlayAll: () => controller.playFrom(tracks, 0),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: tracks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isCurrent = currentId == track.id;
                  return TrackTile(
                    track: track,
                    isCurrent: isCurrent,
                    isPlaying: playing,
                    onTap: () => controller.playFrom([track], 0),
                    trailing: _ResultMenu(l10n: l10n, track: track, controller: controller),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryView extends ConsumerWidget {
  const _HistoryView({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).value ?? const <String>[];
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    if (history.isEmpty) {
      return StateMessage(
        icon: Icons.library_music_outlined,
        title: l10n.searchStartHere,
        subtitle: l10n.searchEmpty,
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.searchPlanLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: scheme.onSurfaceVariant)),
              TextButton(
                onPressed: () => ref.read(historyProvider.notifier).clear(),
                child: Text(l10n.searchClear),
              ),
            ],
          ),
        ),
        for (final item in history)
          ListTile(
            dense: true,
            leading: Icon(Icons.history_rounded, size: 20, color: scheme.onSurfaceVariant),
            title: Text(item, style: const TextStyle(fontSize: 14)),
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => ref.read(historyProvider.notifier).removeAt(history.indexOf(item)),
            ),
            onTap: () => onPick(item),
          ),
      ],
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.l10n, required this.count, required this.onPlayAll});

  final L10n l10n;
  final int count;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        children: [
          Text(
            l10n.searchResults(count),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onPlayAll,
            style: TextButton.styleFrom(foregroundColor: scheme.primary, visualDensity: VisualDensity.compact),
            icon: const Icon(Icons.play_circle_fill_rounded, size: 19),
            label: Text(l10n.playAll),
          ),
        ],
      ),
    );
  }
}

enum _TrackAction { playNow, playNext, enqueue, playlist }

class _ResultMenu extends StatelessWidget {
  const _ResultMenu({required this.l10n, required this.track, required this.controller});

  final L10n l10n;
  final Track track;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final playable = track.source.playable;
    return PopupMenuButton<_TrackAction>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: l10n.moreActions,
      onSelected: (action) async {
        switch (action) {
          case _TrackAction.playNow:
            controller.playFrom([track], 0);
          case _TrackAction.playNext:
            controller.playNext(track);
          case _TrackAction.enqueue:
            controller.addToQueue(track);
          case _TrackAction.playlist:
            await pickPlaylistForTrack(context, track);
        }
      },
      itemBuilder: (_) => [
        if (playable)
          PopupMenuItem(
            value: _TrackAction.playNow,
            height: 44,
            child: _MenuRow(Icons.play_circle_outline_rounded, l10n.playNow),
          ),
        if (playable)
          PopupMenuItem(
            value: _TrackAction.playNext,
            height: 44,
            child: _MenuRow(Icons.playlist_add_rounded, l10n.playNext),
          ),
        PopupMenuItem(
          value: _TrackAction.enqueue,
          height: 44,
          child: _MenuRow(Icons.queue_music_rounded, l10n.addToQueue),
        ),
        PopupMenuItem(
          value: _TrackAction.playlist,
          height: 44,
          child: _MenuRow(Icons.playlist_add_rounded, l10n.addToPlaylist),
        ),
      ],
    );
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
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
