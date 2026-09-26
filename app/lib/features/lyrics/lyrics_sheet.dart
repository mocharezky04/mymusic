import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/widgets/state_shell.dart';
import '../player/player_provider.dart';
import 'lyrics_provider.dart';

class LyricsSheet extends ConsumerWidget {
  const LyricsSheet({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final lyrics = ref.watch(
      lyricsProvider((track: track.title, artist: _artist)),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.lyricsTitle(track.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: lyrics.when(
                loading: () => StateLoading(title: l10n.lyricsLoading),
                error: (err, _) =>
                    _Message(l10n.lyricsNotFound, l10n.lyricsNotInDb),
                data: (result) {
                  if (!result.found) {
                    return _Message(l10n.lyricsNotFound, l10n.lyricsNotInDb);
                  }
                  if (result.synced && result.lrc != null) {
                    return _SyncedView(lyrics: SyncedLyrics.parse(result.lrc!));
                  }
                  return _PlainView(text: result.plain ?? '');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String get _artist => track.artist.isNotEmpty ? track.artist : track.uploader;
}

class _PlainView extends StatelessWidget {
  const _PlainView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, height: 1.7, color: scheme.onSurface),
      ),
    );
  }
}

class _SyncedView extends ConsumerWidget {
  const _SyncedView({required this.lyrics});

  final SyncedLyrics lyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position =
        ref.watch(playerPositionProvider).value?.position ?? Duration.zero;
    var active = -1;
    for (var i = 0; i < lyrics.lines.length; i++) {
      if (lyrics.lines[i].time <= position) {
        active = i;
      } else {
        break;
      }
    }
    final scroll = ScrollController();
    if (active >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          final target = (active * 48.0).clamp(0.0, 48.0 * lyrics.lines.length);
          scroll.jumpTo(target);
        }
      });
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: lyrics.lines.length,
      itemBuilder: (context, index) {
        final isActive = index == active;
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: isActive ? 18 : 14,
            height: 1.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? scheme.primary : scheme.onSurfaceVariant,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
            child: Text(lyrics.lines[index].text, textAlign: TextAlign.center),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
