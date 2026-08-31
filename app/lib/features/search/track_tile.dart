import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import 'eq_bars.dart';
import 'source_badge.dart';

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({super.key, required this.track, this.size = 48, this.radius = 8});

  final Track track;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (track.thumb.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(Icons.music_note, size: size * 0.5, color: scheme.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: track.thumb,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: size,
          height: size,
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.music_note, size: size * 0.5, color: scheme.onSurfaceVariant),
        ),
        errorWidget: (_, _, _) => Container(
          width: size,
          height: size,
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.music_note, size: size * 0.5, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class TrackTile extends ConsumerWidget {
  const TrackTile({
    super.key,
    required this.track,
    this.isCurrent = false,
    this.isPlaying = false,
    this.onTap,
    this.onAdd,
    this.trailing,
  });

  final Track track;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = ref.watch(l10nProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrent ? scheme.primary.withValues(alpha: 0.08) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              TrackArtwork(track: track),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      track.artist.isEmpty ? track.uploader : track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isPlaying && isCurrent)
                EqBars(active: true, height: 14, width: 14)
              else
                SourceBadge(source: track.source),
              const SizedBox(width: 8),
              Text(
                track.durationLabel,
                style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              if (onAdd != null)
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.queue_music, size: 20),
                  tooltip: l10n.addToQueueShort,
                  visualDensity: VisualDensity.compact,
                ),
              if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}