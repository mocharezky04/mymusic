import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/widgets/state_shell.dart';
import '../player/player_provider.dart';
import '../playlist/add_to_playlist_sheet.dart';
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

  /// Kosong = belum ada pencarian disubmit, tampilkan riwayat.
  String _submitted = '';

  /// Isi kolom saat ini. Bedakan dari [_submitted] supaya overlay saran
  /// tahu harus muncul atau tidak.
  String _typed = '';
  List<String> _suggestions = const [];
  Timer? _debounce;
  int _suggestSeq = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _focus.removeListener(_onFocusChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final value = _controller.text;
    if (value == _typed) return;
    setState(() => _typed = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _fetchSuggestions(value),
    );
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) return;
    _debounce?.cancel();
    setState(() => _suggestions = const []);
  }

  Future<void> _fetchSuggestions(String value) async {
    final seq = ++_suggestSeq;
    final results = await ref.read(apiProvider).suggest(value);
    // Abaikan jawaban lama supaya tidak menimpa ketikan yang lebih baru.
    if (seq != _suggestSeq || !mounted) return;
    setState(() => _suggestions = results);
  }

  void _runNow(String value) {
    _debounce?.cancel();
    setState(() {
      _submitted = value;
      _typed = value;
      _suggestions = const [];
    });
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _focus.unfocus();
    ref.read(searchControllerProvider.notifier).run(value);
  }

  void _fillQuery(String value) {
    // Isi kolom tanpa menjalankan pencarian; pengguna menekan Enter sendiri.
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _submitted = '';
      _typed = '';
      _suggestions = const [];
    });
    ref.read(searchControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchControllerProvider);
    final l10n = ref.watch(l10nProvider);
    final showOverlay = _focus.hasFocus && _typed.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onSubmitted: _runNow,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search_outlined, size: 22),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _clear,
                    ),
            ),
          ),
        ),
        Expanded(
          child: showOverlay
              ? _SuggestOverlay(
                  query: _typed,
                  suggestions: _suggestions,
                  onFill: _fillQuery,
                  onPick: _runNow,
                )
              : _submitted.isEmpty
              ? _HistoryView(onPick: _runNow)
              : _ResultsView(results: results, query: _submitted),
        ),
      ],
    );
  }
}

/// Gabungan riwayat pencarian dan saran. Riwayat didahulukan bila isinya
/// mengandung query yang sedang diketik, seperti yang dilakukan YouTube.
class _SuggestOverlay extends ConsumerWidget {
  const _SuggestOverlay({
    required this.query,
    required this.suggestions,
    required this.onFill,
    required this.onPick,
  });

  final String query;
  final List<String> suggestions;
  final ValueChanged<String> onFill;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    final history = ref.watch(historyProvider).value ?? const <String>[];
    final q = query.trim().toLowerCase();

    // Satu daftar tanpa header section: riwayat yang diawali query lebih dulu,
    // lalu riwayat yang hanya mengandung, lalu saran server. Dedup by teks.
    final seen = <String>{};
    final rows = <_OverlayItem>[];
    if (q.isNotEmpty) {
      final starts = <String>[];
      final contains = <String>[];
      for (final item in history) {
        final lower = item.toLowerCase();
        if (lower.startsWith(q)) {
          starts.add(item);
        } else if (lower.contains(q)) {
          contains.add(item);
        }
      }
      for (final item in [...starts, ...contains]) {
        if (seen.add(item.toLowerCase())) {
          rows.add(_OverlayItem.history(item));
        }
      }
    }
    for (final item in suggestions) {
      if (seen.add(item.toLowerCase())) {
        rows.add(_OverlayItem.suggestion(item));
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: scheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          return _OverlayRow(
            icon: row.icon,
            text: row.text,
            highlighted: q,
            onTap: () => onPick(row.text),
            trailing: IconButton(
              icon: const Icon(Icons.north_west_rounded, size: 18),
              tooltip: l10n.useThisQuery,
              onPressed: () => onFill(row.text),
            ),
          );
        },
      ),
    );
  }
}

class _OverlayItem {
  const _OverlayItem._(this.icon, this.text);

  factory _OverlayItem.history(String text) =>
      _OverlayItem._(Icons.history_rounded, text);

  factory _OverlayItem.suggestion(String text) =>
      _OverlayItem._(Icons.search_rounded, text);

  final IconData icon;
  final String text;
}

class _OverlayRow extends StatelessWidget {
  const _OverlayRow({
    required this.icon,
    required this.text,
    required this.highlighted,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String text;
  final String highlighted;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: _HighlightedText(text: text, needle: highlighted),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Teks dengan potongan yang cocok query diberi warna terang + radius kecil,
/// bukan background pill.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.needle});

  final String text;
  final String needle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = const TextStyle(fontSize: 14);
    final needleLower = needle.toLowerCase();
    if (needleLower.isEmpty) {
      return Text(text, style: base.copyWith(color: scheme.onSurface));
    }
    final lower = text.toLowerCase();
    final index = lower.indexOf(needleLower);
    if (index < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base.copyWith(color: scheme.onSurface),
      );
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: base.copyWith(color: scheme.onSurface),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + needle.length),
            style: base.copyWith(
              color: scheme.onSurface,
              backgroundColor: scheme.surfaceContainerHigh,
            ),
          ),
          TextSpan(text: text.substring(index + needle.length)),
        ],
      ),
    );
  }
}

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.results, required this.query});

  final AsyncValue<List<Track>> results;
  final String query;

  String _errorCause(Object err, L10n l10n) {
    if (err is ApiKeyRejectedException) return l10n.appBuildRejected;
    if (err is ServerOfflineException) return l10n.serverUnreachable;
    if (err is DioApiException) return l10n.serverBusy;
    return l10n.searchRetry;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return results.when(
      loading: () => StateLoading(title: l10n.searchLoading),
      error: (err, _) {
        final cause = _errorCause(err, l10n);
        return StateMessage(
          icon: cause == l10n.serverUnreachable
              ? Icons.wifi_off_outlined
              : Icons.cloud_off_outlined,
          title: l10n.searchFailed,
          subtitle: cause,
          action: cause == l10n.appBuildRejected
              ? null
              : TextButton.icon(
                  onPressed: () {
                    ref.read(searchControllerProvider.notifier).run(query);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.tryAgain),
                ),
        );
      },
      data: (tracks) {
        if (tracks.isEmpty) {
          return StateMessage(
            icon: Icons.music_off_outlined,
            title: l10n.searchNoResults,
            subtitle: l10n.searchRetry,
          );
        }
        final videos = tracks.where((t) => t.isPlayable).toList();
        final mixes = tracks.where((t) => t.kind == 'mix').toList();
        if (videos.isEmpty && mixes.isEmpty) {
          return StateMessage(
            icon: Icons.music_off_outlined,
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
        final rows = _interleave(videos, mixes);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultsHeader(
              l10n: l10n,
              count: videos.length,
              onPlayAll: () => controller.playFrom(videos, 0),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  if (row.mix != null) {
                    return _MixCard(
                      mix: row.mix!,
                      onPlay: (mix) => _playMix(context, ref, mix),
                    );
                  }
                  final track = row.video!;
                  final isCurrent = currentId == track.id;
                  return TrackTile(
                    track: track,
                    isCurrent: isCurrent,
                    isPlaying: playing,
                    onTap: () => controller.playFrom([track], 0),
                    trailing: _ResultMenu(
                      l10n: l10n,
                      track: track,
                      controller: controller,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Satu daftar kontinu: video, lalu sisipkan mix di posisi 3, 12, dan
  /// sisanya di akhir. Maksimal 3 mix per halaman.
  static List<_ResultRow> _interleave(List<Track> videos, List<Track> mixes) {
    const firstAt = 3;
    const secondAt = 12;
    final pending = mixes.take(3).toList();
    final rows = <_ResultRow>[];
    for (var i = 0; i < videos.length; i++) {
      if (pending.isNotEmpty && i == firstAt) {
        rows.add(_ResultRow.mix(pending.removeAt(0)));
      }
      if (pending.isNotEmpty && i == secondAt) {
        rows.add(_ResultRow.mix(pending.removeAt(0)));
      }
      rows.add(_ResultRow.video(videos[i]));
    }
    while (pending.isNotEmpty) {
      rows.add(_ResultRow.mix(pending.removeAt(0)));
    }
    return rows;
  }

  Future<void> _playMix(BuildContext context, WidgetRef ref, Track mix) async {
    final l10n = ref.read(l10nProvider);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(playerControllerProvider.notifier);
    try {
      final tracks = await ref
          .read(apiProvider)
          .fetchMixTracks(mixId: mix.id, account: '');
      if (tracks.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.mixLoadFailed)));
        return;
      }
      await controller.playFrom(tracks, 0);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.mixLoadFailed)));
    }
  }
}

/// Kartu radio YouTube Music, ditata di bawah daftar video.
class _ResultRow {
  const _ResultRow._({this.video, this.mix});

  factory _ResultRow.video(Track t) => _ResultRow._(video: t);

  factory _ResultRow.mix(Track t) => _ResultRow._(mix: t);

  final Track? video;
  final Track? mix;
}

/// Kartu mix full-width: artwork 16:9, badge di pojok, judul & artis di bawah.
class _MixCard extends StatelessWidget {
  const _MixCard({required this.mix, required this.onPlay});

  final Track mix;
  final ValueChanged<Track> onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = ProviderScope.containerOf(context).read(l10nProvider);
    final artist = mix.artist.isNotEmpty
        ? mix.artist
        : (mix.uploader.isNotEmpty ? mix.uploader : l10n.mixSubtitle);
    return InkWell(
      onTap: () => onPlay(mix),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MixArt(mix: mix),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 14,
                            color: scheme.onSurface,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.mixBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mix.title.isEmpty ? l10n.mixUntitled : mix.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MixArt extends StatelessWidget {
  const _MixArt({required this.mix});

  final Track mix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      color: scheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.graphic_eq_rounded,
        size: 28,
        color: scheme.onSurfaceVariant,
      ),
    );
    if (mix.thumb.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: fallback,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: CachedNetworkImage(
        imageUrl: mix.thumb,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
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
              Text(
                l10n.searchPlanLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
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
            leading: Icon(
              Icons.history_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            title: Text(item, style: const TextStyle(fontSize: 14)),
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => ref
                  .read(historyProvider.notifier)
                  .removeAt(history.indexOf(item)),
            ),
            onTap: () => onPick(item),
          ),
      ],
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.l10n,
    required this.count,
    required this.onPlayAll,
  });

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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onPlayAll,
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
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
  const _ResultMenu({
    required this.l10n,
    required this.track,
    required this.controller,
  });

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
