import 'package:flutter/material.dart';

import '../../core/models.dart';

class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});

  final TrackSource source;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (source) {
      TrackSource.youtube => const Color(0xFFE53935),
      TrackSource.ytmusic => const Color(0xFF1DB954),
      TrackSource.soundcloud => const Color(0xFFFF5500),
      TrackSource.spotify => const Color(0xFF1DB954),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Text(
        source.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}