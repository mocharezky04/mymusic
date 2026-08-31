import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../player/player_provider.dart';
import '../search/eq_bars.dart';
import '../search/track_tile.dart';
import 'now_playing_screen.dart';
import 'queue_panel.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerControllerProvider.select((s) => s.current));
    final playing = ref.watch(playerControllerProvider.select((s) => s.playing));
    if (track == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final position = ref.watch(playerPositionProvider).value;
    final pos = position?.position ?? Duration.zero;
    final dur = position?.duration ??
        (track.durationSeconds > 0 ? Duration(seconds: track.durationSeconds) : Duration.zero);
    final progress = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 12,
        shadowColor: AppColors.violet.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: _SwipeableMiniContent(
          onSwipeNext: () => ref.read(playerControllerProvider.notifier).next(),
          onSwipePrevious: () {
            final p = position?.position ?? Duration.zero;
            if (p > const Duration(seconds: 3)) {
              ref.read(playerControllerProvider.notifier).seek(Duration.zero);
            } else {
              ref.read(playerControllerProvider.notifier).previous();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: scheme.onSurfaceVariant.withValues(alpha: 0.16)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.violetBright, AppColors.cyan],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      transitionDuration: const Duration(milliseconds: 320),
                      reverseTransitionDuration: const Duration(milliseconds: 240),
                      pageBuilder: (_, _, _) => const NowPlayingScreen(),
                      transitionsBuilder: (_, anim, _, child) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                      fullscreenDialog: true,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'artwork-${track.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: TrackArtwork(track: track, size: 42, radius: AppRadius.sm),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist.isEmpty ? track.uploader : track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      EqBars(active: playing, height: 16, width: 18),
                      IconButton(
                        onPressed: ref.read(playerControllerProvider.notifier).toggle,
                        icon: Icon(
                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 30,
                          color: scheme.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: ref.read(playerControllerProvider.notifier).next,
                        icon: const Icon(Icons.skip_next_rounded, size: 26),
                      ),
                    ],
                  ),
                ),
              ),
              _UpNextStrip(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeableMiniContent extends StatefulWidget {
  const _SwipeableMiniContent({
    required this.child,
    required this.onSwipeNext,
    required this.onSwipePrevious,
  });

  final Widget child;
  final VoidCallback onSwipeNext;
  final VoidCallback onSwipePrevious;

  @override
  State<_SwipeableMiniContent> createState() => _SwipeableMiniContentState();
}

class _SwipeableMiniContentState extends State<_SwipeableMiniContent>
    with SingleTickerProviderStateMixin {
  double _dragDx = 0;
  bool _active = false;

  void _onUpdate(DragUpdateDetails d) {
    if (d.primaryDelta == null) return;
    setState(() {
      _dragDx += d.primaryDelta!;
      final limit = MediaQuery.sizeOf(context).width * 0.35;
      if (_dragDx > limit) _dragDx = limit;
      if (_dragDx < -limit) _dragDx = -limit;
    });
  }

  void _onEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final threshold = 220.0;
    if (_dragDx > 60 || v > threshold) {
      widget.onSwipePrevious();
    } else if (_dragDx < -60 || v < -threshold) {
      widget.onSwipeNext();
    }
    setState(() {
      _dragDx = 0;
      _active = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => setState(() => _active = true),
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: () => setState(() {
        _dragDx = 0;
        _active = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translateByDouble(_dragDx, 0.0, 0.0, 1.0),
        child: Stack(
          children: [
            if (_active && _dragDx.abs() > 8)
              Positioned.fill(
                child: _SwipeHint(dx: _dragDx),
              ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.dx});

  final double dx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showPrev = dx > 0;
    return Container(
      color: (showPrev ? scheme.primary : scheme.secondary).withValues(alpha: 0.12),
      alignment: showPrev ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Opacity(
        opacity: (dx.abs() / 100).clamp(0.0, 1.0),
        child: Icon(
          showPrev ? Icons.skip_previous_rounded : Icons.skip_next_rounded,
          color: showPrev ? scheme.primary : scheme.secondary,
          size: 28,
        ),
      ),
    );
  }
}

class _UpNextStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playerControllerProvider.select((s) => s.queue));
    final index = ref.watch(playerControllerProvider.select((s) => s.index));
    final hasNext = index + 1 < queue.length;
    final next = hasNext ? queue[index + 1] : null;
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);

    return InkWell(
      onTap: () => QueuePanel.show(context),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          border: Border(
            top: BorderSide(color: scheme.onSurface.withValues(alpha: 0.10)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        child: Row(
          children: [
            Icon(Icons.queue_music_rounded, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasNext
                    ? '${l10n.upNext} • ${next!.title} — ${next.artist.isEmpty ? next.uploader : next.artist}'
                    : l10n.queueEmptyTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.expand_less_rounded, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
