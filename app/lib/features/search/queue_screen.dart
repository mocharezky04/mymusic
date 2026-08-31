import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/widgets/state_shell.dart';
import '../player/player_provider.dart';
import '../search/track_tile.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playerControllerProvider.select((s) => s.queue));
    final index = ref.watch(playerControllerProvider.select((s) => s.index));
    final playing = ref.watch(playerControllerProvider.select((s) => s.playing));
    final controller = ref.read(playerControllerProvider.notifier);
    final l10n = ref.watch(l10nProvider);

    if (queue.isEmpty) {
      return StateMessage(
        icon: Icons.queue_music_rounded,
        title: l10n.queueEmptyTitle,
        subtitle: l10n.queueEmptySubtitle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.queueCount(queue.length),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
              IconButton(
                onPressed: controller.clearQueue,
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                tooltip: l10n.clearQueue,
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            buildDefaultDragHandles: false,
            itemCount: queue.length,
            onReorderItem: (oldIndex, newIndex) =>
                controller.reorder(oldIndex, newIndex),
            itemBuilder: (context, itemIndex) {
              final item = queue[itemIndex];
              final isCurrent = itemIndex == index;
              return ReorderableDelayedDragStartListener(
                key: ValueKey('${item.id}-$itemIndex'),
                index: itemIndex,
                child: TrackTile(
                  track: item,
                  isCurrent: isCurrent,
                  isPlaying: playing,
                  onTap: () => controller.playFrom(queue, itemIndex),
                  trailing: const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.drag_indicator, size: 18),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}