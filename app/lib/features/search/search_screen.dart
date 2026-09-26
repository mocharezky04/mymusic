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
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetchSuggestions(value));
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
    final q = query.toLowerCase();

    final historyMatches =
        history.where((h) => h.toLowerCase().contains(q)).toList();
    final historyRest =
        history.where((h) => !h.toLowerCase().contains(q)).toList();
    final seen = <String>{...historyMatches};
    final freshSuggestions =
        suggestions.where((s) => !seen.contains(s)).toList();

    if (history.isEmpty && suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (historyMatches.isNotEmpty) ...[
          _OverlayLabel(l10n.searchHistoryLabel),
          for (final item in historyMatches)
            _OverlayRow(
              icon: Icons.history_rounded,
              text: item,
              highlighted: q,
              onTap: () => onPick(item),
            ),
        ],
        if (historyRest.isNotEmpty) ...[
          _OverlayLabel(l10n.searchHistoryLabel),
          for (final item in historyRest)
            _OverlayRow(
              icon: Icons.history_rounded,
              text: item,
              highlighted: q,
              onTap: () => onPick(item),
            ),
        ],
        if (freshSuggestions.isNotEmpty) ...[
          _OverlayLabel(l10n.searchSuggestionsLabel),
          for (final item in freshSuggestions)
            _OverlayRow(
              icon: Icons.search_rounded,
              text: item,
              highlighted: q,
              onTap: () => onPick(item),
              trailing: IconButton(
                icon: const Icon(Icons.north_west_rounded, size: 18),
                tooltip: l10n.useThisQuery,
                onPressed: () => onFill(item),
              ),
            ),
        ],
      ],
    ).withBackground(scheme);
  }
}

extension on Widget {
  Widget withBackground(ColorScheme scheme) => ColoredBox(
        color: scheme.surface,
        child: this,
      );
}

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (videos.isNotEmpty) ...[
              _ResultsHeader(
                l10n: l10n,
                count: videos.length,
                onPlayAll: () => controller.playFrom(videos, 0),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: videos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final track = videos[index];
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
            ] else
              const Spacer(),
            if (mixes.isNotEmpty)
              _MixSection(
                mixes: mixes,
                onPlay: (mix) => _playMix(context, ref, mix),
              ),
          ],
        );
      },
    );
  }

  Future<void> _playMix(
    BuildContext context,
    WidgetRef ref,
    Track mix,
  ) async {
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
class _MixSection extends StatelessWidget {
  const _MixSection({required this.mixes, required this.onPlay});

  final List<Track> mixes;
  final ValueChanged<Track> onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = ProviderScope.containerOf(context).read(l10nProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              l10n.mixBadge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final mix in mixes)
            InkWell(
              onTap: () => onPlay(mix),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _MixThumb(mix: mix),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mix.title.isEmpty
                                ? l10n.mixUntitled
                                : mix.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.mixSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Icon(
                        Icons.graphic_eq_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MixThumb extends StatelessWidget {
  const _MixThumb({required this.mix});

  final Track mix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (mix.thumb.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          Icons.graphic_eq_rounded,
          size: 22,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: CachedNetworkImage(
        imageUrl: mix.thumb,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: 56,
          height: 56,
          color: scheme.surfaceContainerHighest,
        ),
        errorWidget: (_, _, _) => Container(
          width: 56,
          height: 56,
          color: scheme.surfaceContainerHighest,
          child: Icon(
            Icons.graphic_eq_rounded,
            size: 22,
            color: scheme.onSurfaceVariant,
          ),
        ),
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
