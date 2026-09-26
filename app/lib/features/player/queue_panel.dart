import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../playlist/add_to_playlist_sheet.dart';
import '../player/player_provider.dart';
import '../search/track_tile.dart';

class QueuePanel extends ConsumerWidget {
  const QueuePanel({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const QueuePanel(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playerControllerProvider.select((s) => s.queue));
    final currentIndex = ref.watch(
      playerControllerProvider.select((s) => s.index),
    );
    final playing = ref.watch(
      playerControllerProvider.select((s) => s.playing),
    );
    final controller = ref.read(playerControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    final mediaQuery = MediaQuery.of(context);

    final current = (currentIndex >= 0 && currentIndex < queue.length)
        ? queue[currentIndex]
        : null;
    final upcomingStart = current == null ? 0 : currentIndex + 1;
    final upcoming = upcomingStart < queue.length
        ? queue.sublist(upcomingStart)
        : <dynamic>[];

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.75),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.queue_music_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.queue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (queue.isNotEmpty)
                      IconButton(
                        onPressed: () => _confirmClear(context, ref),
                        icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                        tooltip: l10n.clearQueue,
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.expand_more_rounded, size: 22),
                      tooltip: l10n.close,
                    ),
                  ],
                ),
              ),
              if (queue.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.queue_music_rounded,
                            size: 40,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.queueEmptyTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.queueEmptySubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      if (current != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                          child: Text(
                            l10n.nowPlaying.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        TrackTile(
                          track: current,
                          isCurrent: true,
                          isPlaying: playing,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          current == null ? 8 : 14,
                          20,
                          6,
                        ),
                        child: Row(
                          children: [
                            Text(
                              l10n.upNextShort.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${upcoming.length}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.reorderHint,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (upcoming.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Text(
                            l10n.queueEmptySubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: upcoming.length,
                          onReorderItem: (oldIndex, newIndex) {
                            final qOld = upcomingStart + oldIndex;
                            final qNew = upcomingStart + newIndex;
                            if (qOld != qNew) controller.reorder(qOld, qNew);
                          },
                          itemBuilder: (context, i) {
                            final t = upcoming[i];
                            final sourceIndex = upcomingStart + i;
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey('qp-${t.id}-$sourceIndex'),
                              index: i,
                              child: _DismissibleQueueItem(
                                track: t,
                                onTap: () {
                                  controller.playFrom(queue, sourceIndex);
                                  Navigator.of(context).pop();
                                },
                                onRemove: () => _removeAndUndo(
                                  context,
                                  ref,
                                  sourceIndex,
                                  t.title,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    final l10n = ref.read(l10nProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearQueueTitle),
        content: Text(l10n.clearQueueConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(playerControllerProvider.notifier).clearQueue();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.clearQueue),
          ),
        ],
      ),
    );
  }

  void _removeAndUndo(
    BuildContext context,
    WidgetRef ref,
    int index,
    String title,
  ) {
    final controller = ref.read(playerControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final currentState = ref.read(playerControllerProvider);
    final queue = List.of(currentState.queue);
    if (index < 0 || index >= queue.length) return;
    final removed = queue[index];
    final shift = index <= currentState.index;
    controller.removeAt(index);
    final l10n = ref.read(l10nProvider);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.removedFromQueue(title)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            final latest = ref.read(playerControllerProvider);
            final target = (index <= latest.queue.length)
                ? index
                : latest.queue.length;
            controller.addAt(removed, target, shiftCurrent: shift);
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class _DismissibleQueueItem extends ConsumerWidget {
  const _DismissibleQueueItem({
    required this.track,
    required this.onTap,
    required this.onRemove,
  });

  final dynamic track;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    return Dismissible(
      key: ValueKey('d-${track.id}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onRemove(),
      background: _swipeBg(
        context,
        align: Alignment.centerLeft,
        color: AppColors.pinkCoral,
        icon: Icons.remove_rounded,
      ),
      secondaryBackground: _swipeBg(
        context,
        align: Alignment.centerRight,
        color: AppColors.pinkCoral,
        icon: Icons.remove_rounded,
      ),
      child: Container(
        color: scheme.surface,
        child: TrackTile(
          track: track,
          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                tooltip: l10n.removeFromQueueShort,
              ),
              AddToPlaylistIconButton(track: track),
              const Padding(
                padding: EdgeInsets.only(left: 4, right: 6),
                child: Icon(Icons.drag_indicator, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swipeBg(
    BuildContext context, {
    required Alignment align,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      color: color.withValues(alpha: 0.85),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
