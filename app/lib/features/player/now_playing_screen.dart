import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../lyrics/lyrics_sheet.dart';
import '../search/eq_bars.dart';
import '../search/search_providers.dart' show apiProvider;
import '../search/track_tile.dart';
import '../storage/download_service.dart';
import 'player_provider.dart';

String _fmt(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(playerControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    final track = ref.watch(playerControllerProvider.select((s) => s.current));
    final playing = ref.watch(playerControllerProvider.select((s) => s.playing));
    final loading = ref.watch(playerControllerProvider.select((s) => s.loading));
    final hasTrack = ref.watch(playerControllerProvider.select((s) => s.hasTrack));
    final repeat = ref.watch(playerControllerProvider.select((s) => s.repeat));
    final shuffle = ref.watch(playerControllerProvider.select((s) => s.shuffle));
    final position = ref.watch(playerPositionProvider).value;
    final pos = position?.position ?? Duration.zero;
    final dur = position?.duration ??
        (track != null ? Duration(seconds: track.durationSeconds) : Duration.zero);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.nowPlaying,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: scheme.onSurfaceVariant),
        ),
        centerTitle: true,
        toolbarHeight: 44,
        actions: [
          if (!kIsWeb && track != null) ...[
            _DownloadButton(track: track, l10n: l10n),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.lyrics_outlined, size: 23),
            tooltip: l10n.lyrics,
            onPressed: track == null
                ? null
                : () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: scheme.surfaceContainerLow,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                      ),
                      builder: (_) => LyricsSheet(track: track),
                    ),
          ),
        ],
      ),
      body: track == null
          ? Center(
              child: Text(l10n.noPlayer, style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          : GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _verticalDragDelta = (_verticalDragDelta ?? 0) + (details.primaryDelta ?? 0);
                  if (_verticalDragDelta! < 0) _verticalDragDelta = 0;
                });
              },
              onVerticalDragEnd: (details) {
                final dy = _verticalDragDelta ?? 0;
                final vy = details.primaryVelocity ?? 0;
                _verticalDragDelta = null;
                if (dy > 120 || vy > 800) {
                  Navigator.of(context).maybePop();
                } else {
                  setState(() {});
                }
              },
              child: Transform.translate(
                offset: Offset(0, (_verticalDragDelta ?? 0).clamp(0.0, 200.0)),
                child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.violet.withValues(alpha: 0.32),
                          AppColors.cyan.withValues(alpha: 0.10),
                          scheme.surface.withValues(alpha: 0.0),
                          scheme.surface,
                        ],
                        stops: const [0.0, 0.30, 0.55, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: GestureDetector(
                              onHorizontalDragEnd: (details) {
                                if (details.primaryVelocity == null) return;
                                if (details.primaryVelocity! < -600) {
                                  controller.next();
                                } else if (details.primaryVelocity! > 600) {
                                  controller.previous();
                                }
                              },
                              child: _GlowArtwork(track: track, playing: playing),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.15),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    track.artist.isEmpty ? track.uploader : track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            if (playing) ...[
                              const SizedBox(width: 14),
                              EqBars(active: true, height: 18, width: 22),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Slider(
                          value: dur.inMilliseconds > 0
                              ? (_dragMs ?? _clampMs(pos, dur))
                              : 0,
                          max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
                          onChanged: dur.inMilliseconds > 0
                              ? (v) => setState(() => _dragMs = v)
                              : null,
                          onChangeEnd: dur.inMilliseconds > 0
                              ? (v) {
                                  controller.seek(Duration(milliseconds: v.round()));
                                  setState(() => _dragMs = null);
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(Duration(milliseconds: _dragMs?.round() ?? pos.inMilliseconds)), style: _timeStyle(scheme)),
                              Text(_fmt(dur), style: _timeStyle(scheme)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _CircleButton(
                                icon: Icons.shuffle_rounded,
                                active: shuffle,
                                activeDot: shuffle,
                                onPressed: hasTrack ? () => controller.toggleShuffle() : null,
                              ),
                            ),
                            _CircleButton(
                              icon: Icons.skip_previous_rounded,
                              size: 36,
                              onPressed: hasTrack ? controller.previous : null,
                            ),
                            _PlayButton(playing: playing, loading: loading, onPressed: hasTrack ? controller.toggle : null),
                            _CircleButton(
                              icon: Icons.skip_next_rounded,
                              size: 36,
                              onPressed: hasTrack ? controller.next : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CircleButton(
                                icon: repeat == PlaybackRepeat.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                                active: repeat != PlaybackRepeat.off,
                                activeDot: repeat != PlaybackRepeat.off,
                                onPressed: hasTrack ? controller.cycleRepeat : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  double? _verticalDragDelta;

  TextStyle _timeStyle(ColorScheme scheme) =>
      TextStyle(fontSize: 11, fontFeatures: const [FontFeature.tabularFigures()], color: scheme.onSurfaceVariant);

  double _clampMs(Duration position, Duration duration) {
    if (duration.inMilliseconds <= 0) return 0;
    final ms = position.inMilliseconds.clamp(0, duration.inMilliseconds);
    return ms.toDouble();
  }
}

class _GlowArtwork extends StatelessWidget {
  const _GlowArtwork({required this.track, required this.playing});

  final Track track;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 300,
          height: 300,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: playing ? 0.55 : 0.28),
                blurRadius: 110,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: playing ? 0.35 : 0.18),
                blurRadius: 80,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Hero(
            tag: 'artwork-${track.id}',
            child: Material(
              type: MaterialType.transparency,
              child: TrackArtwork(track: track, size: 300, radius: 24),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.onPressed,
    this.active = false,
    this.activeDot = false,
    this.size = 30,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final bool activeDot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !active
        ? (onPressed == null ? scheme.onSurfaceVariant.withValues(alpha: 0.35) : scheme.onSurfaceVariant)
        : scheme.primary;
    return IconButton(
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: size, color: color),
          if (activeDot)
            Positioned(
              bottom: -12,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.loading, this.onPressed});

  final bool playing;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      shape: const CircleBorder(),
      color: scheme.primary,
      elevation: 8,
      shadowColor: scheme.primary.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 82,
          height: 82,
          child: Icon(
            loading
                ? Icons.hourglass_top_rounded
                : (playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            size: 46,
            color: scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _DownloadButton extends ConsumerStatefulWidget {
  const _DownloadButton({required this.track, required this.l10n});

  final Track track;
  final L10n l10n;

  @override
  ConsumerState<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<_DownloadButton> {
  bool _available = false;
  bool _busy = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final exists = await ref.read(downloadServiceProvider).existing(widget.track);
    if (mounted) setState(() => _available = exists != null);
  }

Future<void> _start() async {
    final service = ref.read(downloadServiceProvider);
    final l10n = widget.l10n;
    setState(() {
      _busy = true;
      _progress = 0;
    });
    try {
      final info = await ref.read(apiProvider).streamInfo(widget.track.id);
      await service.download(
        widget.track,
        info.url,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _available = true;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${widget.track.title}" ${l10n.downloadSavedForOffline}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.downloadFailed)),
      );
    }
  }

  Future<void> _remove() async {
    final l10n = widget.l10n;
    await ref.read(downloadServiceProvider).remove(widget.track);
    if (!mounted) return;
    setState(() => _available = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.downloadRemoved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    if (_busy) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: _progress <= 0 ? null : _progress,
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(
        _available ? Icons.download_done_rounded : Icons.download_rounded,
        size: 22,
      ),
      tooltip: _available ? l10n.removeDownload : l10n.saveForOffline,
      onPressed: _available ? _remove : _start,
    );
  }
}
