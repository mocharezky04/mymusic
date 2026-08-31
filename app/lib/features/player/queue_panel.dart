import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
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
    final currentIndex = ref.watch(playerControllerProvider.select((s) => s.index));
    final controller = ref.read(playerControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    final mediaQuery = MediaQuery.of(context);

    final upcoming = currentIndex + 1 < queue.length
        ? queue.sublist(currentIndex + 1)
        : <dynamic>[];

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.7),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, -8),
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
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                child: Row(
                  children: [
                    Text(
                      l10n.upNext,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.expand_more_rounded, size: 22),
                      tooltip: l10n.close,
                    ),
                  ],
                ),
              ),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
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
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    shrinkWrap: true,
                    itemCount: upcoming.length,
                    itemBuilder: (context, i) {
                      final t = upcoming[i];
                      final sourceIndex = currentIndex + 1 + i;
                      return _DismissibleQueueItem(
                        key: ValueKey('qp-${t.id}-$sourceIndex'),
                        track: t,
                        onTap: () {
                          controller.playFrom(queue, sourceIndex);
                          Navigator.of(context).pop();
                        },
                        onRemove: () => _removeAndUndo(context, ref, sourceIndex, t.title),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeAndUndo(BuildContext context, WidgetRef ref, int index, String title) {
    final controller = ref.read(playerControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final currentState = ref.read(playerControllerProvider);
    final queue = List.of(currentState.queue);
    if (index < 0 || index >= queue.length) return;
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
            controller.reorder(index, queue.length - 1);
            if (index <= currentState.index) {
              controller.playFrom(ref.read(playerControllerProvider).queue, index);
            }
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class _DismissibleQueueItem extends StatelessWidget {
  const _DismissibleQueueItem({
    super.key,
    required this.track,
    required this.onTap,
    required this.onRemove,
  });

  final dynamic track;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        child: TrackTile(track: track, onTap: onTap),
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
